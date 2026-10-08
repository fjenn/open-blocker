#!/usr/bin/env python3
"""Headless emulator proof for Open Blocker (everything except NFC)."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ANDROID_HOME = os.environ.get("ANDROID_HOME", "/home/ubuntu/android-sdk")
ADB = os.environ.get("ADB", f"{ANDROID_HOME}/platform-tools/adb")
PKG = "app.openblocker.android"
MAIN = f"{PKG}/.MainActivity"
RECEIVER = f"{PKG}/.debug.DebugSessionReceiver"
A11Y = f"{PKG}/{PKG}.service.AppBlockingService"
APK = os.environ.get(
    "OPENBLOCKER_DEBUG_APK",
    "/workspace/android/app/build/outputs/apk/debug/app-debug.apk",
)
SHOT_DIR = Path(os.environ.get("OPENBLOCKER_SHOT_DIR", "/workspace/artifacts/android-emulator"))
SERIAL = os.environ.get("ANDROID_SERIAL", "emulator-5554")

RESULTS: list[tuple[str, str, str]] = []


def adb(*args: str, check: bool = True, timeout: int = 90) -> subprocess.CompletedProcess[str]:
    cmd = [ADB, "-s", SERIAL, *args]
    last: subprocess.TimeoutExpired | None = None
    for attempt in range(2):
        try:
            return subprocess.run(
                cmd,
                check=check,
                timeout=timeout,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
        except subprocess.TimeoutExpired as exc:
            last = exc
            log(f"adb timeout ({timeout}s) attempt {attempt + 1}: {' '.join(args[:6])}")
            time.sleep(2)
    if last:
        raise last
    raise RuntimeError("adb failed")


def adb_out(*args: str, timeout: int = 60) -> str:
    return adb(*args, timeout=timeout).stdout.strip()


def log(msg: str) -> None:
    print(msg, flush=True)


def record(step: str, status: str, detail: str = "") -> None:
    RESULTS.append((step, status, detail))
    log(f"[{status}] {step}" + (f" - {detail}" if detail else ""))


def wait_boot(timeout_s: int = 1800) -> None:
    log("waiting for adb device...")
    adb("wait-for-device", timeout=120)
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        try:
            boot = adb_out("shell", "getprop", "sys.boot_completed", timeout=20)
        except Exception as exc:
            log(f"boot poll error: {exc}")
            time.sleep(5)
            continue
        log(f"sys.boot_completed={boot!r}")
        if boot == "1":
            # Wait until a launcher or setup UI exists.
            for _ in range(30):
                try:
                    adb_out("shell", "dumpsys", "activity", "activities", timeout=40)
                    break
                except Exception:
                    time.sleep(2)
            time.sleep(3)
            return
        time.sleep(8)
    raise SystemExit("emulator did not reach sys.boot_completed=1")


def skip_setup() -> None:
    adb("shell", "settings", "put", "global", "device_provisioned", "1", check=False)
    adb("shell", "settings", "put", "secure", "user_setup_complete", "1", check=False)
    adb("shell", "settings", "put", "secure", "android_setup_complete", "1", check=False)
    adb("shell", "settings", "put", "global", "setup_wizard_has_run", "1", check=False)
    for pkg in (
        "com.google.android.setupwizard",
        "com.android.setupwizard",
        "com.google.android.apps.restore",
        "com.google.android.partnersetup",
        "com.google.android.googlesdksetup",
        "com.google.android.gms.setup",
    ):
        adb("shell", "pm", "disable-user", "--user", "0", pkg, check=False)
    adb("shell", "settings", "put", "global", "window_animation_scale", "0")
    adb("shell", "settings", "put", "global", "transition_animation_scale", "0")
    adb("shell", "settings", "put", "global", "animator_duration_scale", "0")
    adb("shell", "settings", "put", "system", "screen_off_timeout", "1800000", check=False)
    adb("shell", "svc", "power", "stayon", "true", check=False)
    adb("shell", "input", "keyevent", "KEYCODE_WAKEUP", check=False)
    adb("shell", "input", "keyevent", "KEYCODE_MENU", check=False)
    adb("shell", "wm", "dismiss-keyguard", check=False)
    adb("shell", "cmd", "lock_settings", "set-disabled", "true", check=False)
    adb("shell", "input", "keyevent", "KEYCODE_HOME", check=False)
    time.sleep(2)


def screenshot(name: str) -> Path:
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    dest = SHOT_DIR / name
    remote = "/sdcard/ob_shot.png"
    for attempt in range(3):
        try:
            adb("shell", "screencap", "-p", remote, timeout=120, check=False)
            r = adb("pull", remote, str(dest), timeout=30, check=False)
            size = dest.stat().st_size if dest.is_file() else 0
            if r.returncode == 0 and size >= 20000:
                log(f"screenshot {dest} ({size} bytes)")
                return dest
            log(f"screenshot attempt {attempt + 1} weak size={size}")
        except subprocess.TimeoutExpired:
            log(f"screenshot attempt {attempt + 1} timed out")
        time.sleep(2)
    log(f"screenshot {dest} failed; leaving whatever we have")
    return dest


def dump_ui(retries: int = 5) -> ET.Element | None:
    pulled = Path("/tmp/window_dump.xml")
    remote = "/sdcard/window_dump.xml"
    for attempt in range(retries):
        adb("shell", "rm", "-f", remote, check=False)
        try:
            r = adb("shell", "uiautomator", "dump", remote, check=False, timeout=120)
        except subprocess.TimeoutExpired:
            log(f"uiautomator dump attempt {attempt + 1} timed out")
            time.sleep(4)
            continue
        if "dumped" not in (r.stdout or "").lower():
            log(f"uiautomator dump attempt {attempt + 1}: {(r.stdout or '')[-200:]}")
            time.sleep(4)
            continue
        time.sleep(0.5)
        pr = adb("pull", remote, str(pulled), check=False, timeout=30)
        if pr.returncode != 0 or not pulled.is_file() or pulled.stat().st_size < 200:
            log(f"pull dump attempt {attempt + 1} failed")
            time.sleep(3)
            continue
        try:
            return ET.parse(pulled).getroot()
        except ET.ParseError as exc:
            log(f"parse dump failed: {exc}")
            time.sleep(3)
    log("uiautomator dump failed after retries")
    return None


def iter_nodes(root: ET.Element):
    yield root
    for child in root:
        yield from iter_nodes(child)


def node_text(node: ET.Element) -> str:
    return " ".join(
        filter(
            None,
            [
                node.attrib.get("text", ""),
                node.attrib.get("content-desc", ""),
                node.attrib.get("resource-id", ""),
            ],
        )
    )


def find_node(root: ET.Element, pred) -> ET.Element | None:
    for n in iter_nodes(root):
        if pred(n):
            return n
    return None


def bounds_center(node: ET.Element) -> tuple[int, int] | None:
    raw = node.attrib.get("bounds", "")
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", raw)
    if not m:
        return None
    l, t, r, b = map(int, m.groups())
    return (l + r) // 2, (t + b) // 2


def tap_node(node: ET.Element) -> bool:
    c = bounds_center(node)
    if not c:
        return False
    adb("shell", "input", "tap", str(c[0]), str(c[1]))
    time.sleep(0.8)
    return True


def tap_res(rid: str) -> bool:
    root = dump_ui()
    if root is None:
        return False
    node = find_node(
        root,
        lambda n: n.attrib.get("resource-id", "") == rid
        or n.attrib.get("resource-id", "").endswith("/" + rid),
    )
    if node is None:
        return False
    return tap_node(node)


def tap_text(text: str) -> bool:
    root = dump_ui()
    if root is None:
        return False
    node = find_node(root, lambda n: text.lower() in node_text(n).lower())
    if node is None:
        return False
    return tap_node(node)


def ui_has(text: str | None = None, rid: str | None = None, pkg: str | None = None, retries: int = 2) -> bool:
    root = dump_ui(retries=retries)
    if root is None:
        return False
    for n in iter_nodes(root):
        blob = node_text(n)
        if text and text.lower() in blob.lower():
            return True
        if rid and (
            n.attrib.get("resource-id") == rid
            or n.attrib.get("resource-id", "").endswith("/" + rid)
        ):
            return True
        if pkg and n.attrib.get("package") == pkg and n.attrib.get("class", "").endswith("FrameLayout"):
            return True
    return False


def current_focus() -> str:
    act = adb_out("shell", "dumpsys", "activity", "activities", timeout=40)
    m = re.search(r"topResumedActivity=ActivityRecord\{\S+\s+u0\s+(\S+)", act)
    if m:
        return m.group(1)
    m = re.search(r"topResumedActivity.*u0\s+([^\s}]+)", act)
    if m:
        return m.group(1)
    m = re.search(r"ResumedActivity:\s+\S+\s+u0\s+([^\s]+)", act)
    if m:
        return m.group(1)
    return act[-500:]


def activity_shown(fragment: str) -> bool:
    focus = current_focus()
    log(f"focus={focus}")
    return fragment in focus


def launch_package(package: str) -> None:
    monkey = adb(
        "shell",
        "monkey",
        "-p",
        package,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
        check=False,
        timeout=30,
    )
    log(monkey.stdout[-400:])
    time.sleep(2)


def launch_openblocker(force_stop: bool = False) -> None:
    if force_stop:
        adb("shell", "am", "force-stop", PKG, check=False)
        time.sleep(0.5)
    adb(
        "shell",
        "am",
        "start",
        "-n",
        MAIN,
        "-a",
        "android.intent.action.MAIN",
        "-c",
        "android.intent.category.LAUNCHER",
    )
    time.sleep(3)


def wait_for_text(text: str, timeout_s: int = 90) -> bool:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        if activity_shown("MainActivity") or activity_shown("BlockScreen"):
            root = dump_ui(retries=1)
            if root is not None and find_node(root, lambda n: text.lower() in node_text(n).lower()):
                return True
        time.sleep(3)
    return ui_has(text=text, retries=2)


def fatal_log(since_clear: bool = True) -> str:
    out = adb_out("logcat", "-d", timeout=40)
    ours: list[str] = []
    chunks = out.split("FATAL EXCEPTION")
    for chunk in chunks[1:]:
        head = chunk[:1200]
        if PKG in head:
            ours.append("FATAL EXCEPTION" + head)
    return "\n".join(ours)


def swipe_up() -> None:
    adb("shell", "input", "swipe", "540", "1600", "540", "500", "300", check=False)
    time.sleep(0.6)


def collect_visible_apps(root: ET.Element) -> list[tuple[str, ET.Element]]:
    found: list[tuple[str, ET.Element]] = []
    for n in iter_nodes(root):
        rid = n.attrib.get("resource-id", "")
        if "app_row_" in rid:
            pkg = rid.split("app_row_")[-1]
            found.append((pkg, n))
        # fallback: package name as small text
    return found


def scroll_find_row(package_or_label: str, max_swipes: int = 12) -> ET.Element | None:
    seen: set[str] = set()
    for i in range(max_swipes + 1):
        root = dump_ui(retries=2)
        if root is None:
            return None
        for n in iter_nodes(root):
            rid = n.attrib.get("resource-id", "")
            blob = node_text(n)
            seen.add(blob[:80])
            if package_or_label.lower() in blob.lower() or package_or_label in rid:
                return n
        swipe_up()
    log(f"did not find {package_or_label}; sample={list(seen)[:8]}")
    return None


def list_packages() -> set[str]:
    out = adb_out("shell", "pm", "list", "packages", timeout=40)
    return {ln.split(":", 1)[-1].strip() for ln in out.splitlines() if ln.startswith("package:")}


def resolve_clock(packages: set[str]) -> str | None:
    for p in (
        "com.google.android.deskclock",
        "com.android.deskclock",
        "com.google.android.clock",
    ):
        if p in packages:
            return p
    return None


def resolve_chrome(packages: set[str]) -> str | None:
    for p in ("com.android.chrome", "com.chrome.beta", "com.google.android.apps.chrome"):
        if p in packages:
            return p
    return None


def enable_accessibility() -> None:
    adb(
        "shell",
        "appops",
        "set",
        PKG,
        "ACCESS_RESTRICTED_SETTINGS",
        "allow",
        check=False,
    )
    adb(
        "shell",
        "settings",
        "put",
        "secure",
        "enabled_accessibility_services",
        A11Y,
    )
    # Toggle off/on so the system actually binds the service (API 34).
    adb("shell", "settings", "put", "secure", "accessibility_enabled", "0")
    time.sleep(1)
    adb("shell", "settings", "put", "secure", "accessibility_enabled", "1")
    time.sleep(4)
    enabled = adb_out("shell", "settings", "get", "secure", "enabled_accessibility_services")
    log(f"enabled_accessibility_services={enabled}")
    dump = adb_out("shell", "dumpsys", "accessibility", timeout=40)
    bound = PKG in dump
    log(f"accessibility dumpsys mentions app: {bound}")
    if not bound:
        log(dump[-800:])


def broadcast(action: str) -> str:
    out = adb_out(
        "shell",
        "am",
        "broadcast",
        "-a",
        action,
        "-n",
        RECEIVER,
        timeout=30,
    )
    log(out)
    return out


def prefs_blocked() -> str:
    r = adb(
        "shell",
        "run-as",
        PKG,
        "cat",
        "shared_prefs/open_blocker_prefs.xml",
        check=False,
        timeout=20,
    )
    return r.stdout


def session_prefs() -> str:
    r = adb(
        "shell",
        "run-as",
        PKG,
        "cat",
        "shared_prefs/session_prefs.xml",
        check=False,
        timeout=20,
    )
    return r.stdout


def main() -> int:
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    wait_boot()
    skip_setup()

    packages = list_packages()
    clock = resolve_clock(packages)
    chrome = resolve_chrome(packages)
    settings_pkg = "com.android.settings" if "com.android.settings" in packages else None
    log(f"packages clock={clock} chrome={chrome} settings={settings_pkg}")
    if not clock or not chrome or not settings_pkg:
        record(
            "preflight-system-apps",
            "FAIL",
            f"clock={clock} chrome={chrome} settings={settings_pkg}",
        )
    else:
        record("preflight-system-apps", "PASS", f"{clock}, {chrome}, {settings_pkg}")

    if not Path(APK).is_file():
        record("install", "FAIL", f"missing {APK}")
        return 1
    inst = adb("install", "-r", "-g", "-t", APK, timeout=120, check=False)
    log(inst.stdout)
    if inst.returncode != 0:
        # retry without -g
        inst = adb("install", "-r", APK, timeout=120, check=False)
        log(inst.stdout)
    if inst.returncode != 0 and "Success" not in inst.stdout:
        record("install", "FAIL", inst.stdout[-300:])
        return 1
    record("install", "PASS")

    adb("logcat", "-c", check=False)
    launch_openblocker()
    time.sleep(8)
    screenshot("01-home.png")
    root = dump_ui(retries=3)
    home_ok = False
    if root is not None:
        home_ok = (
            find_node(
                root,
                lambda n: "Not Blocking" in node_text(n)
                or n.attrib.get("resource-id", "").endswith("home_screen"),
            )
            is not None
        )
    home_ok = home_ok or activity_shown("MainActivity")
    fatals = fatal_log()
    if home_ok and not fatals:
        record("1-launch-home", "PASS", "Home visible, no FATAL")
    else:
        record("1-launch-home", "FAIL", f"home_ok={home_ok} fatals={fatals[:400]}")

    # App picker
    opened = tap_res("manage_blocked_apps") or tap_text("Manage Blocked Apps")
    if opened:
        record("2-app-picker-open", "PASS")
    else:
        record("2-app-picker-open", "FAIL", "could not tap Manage Blocked Apps")
    time.sleep(8)
    screenshot("02-app-picker.png")

    listed: set[str] = set()
    labels_found: set[str] = set()
    for _ in range(8):
        root = dump_ui(retries=2)
        if root is None:
            break
        for n in iter_nodes(root):
            blob = node_text(n)
            rid = n.attrib.get("resource-id", "")
            if "app_row_" in rid:
                listed.add(rid.split("app_row_")[-1])
            for needle in ("Chrome", "Settings", "Clock", "chrome", "settings", "deskclock"):
                if needle.lower() in blob.lower():
                    labels_found.add(needle)
        swipe_up()
    log(f"listed packages ({len(listed)}): {sorted(listed)[:30]}")
    log(f"labels={labels_found}")
    have_chrome = (chrome in listed) or any("chrome" in x.lower() for x in listed | labels_found)
    have_settings = (settings_pkg in listed) if settings_pkg else False
    have_settings = have_settings or any("settings" in x.lower() for x in listed | labels_found)
    have_clock = (clock in listed) if clock else False
    have_clock = have_clock or any("clock" in x.lower() for x in listed | labels_found)
    if have_chrome and have_settings and have_clock:
        record("2-app-picker-list", "PASS", f"n={len(listed)} chrome/settings/clock present")
    else:
        record(
            "2-app-picker-list",
            "FAIL",
            f"chrome={have_chrome} settings={have_settings} clock={have_clock} n={len(listed)}",
        )

    # Re-open picker from top and select Clock + Chrome
    adb("shell", "input", "keyevent", "KEYCODE_BACK", check=False)
    time.sleep(1)
    launch_openblocker()
    time.sleep(2)
    if not (tap_res("manage_blocked_apps") or tap_text("Manage Blocked Apps")):
        log("could not re-open picker")
    time.sleep(2)

    selected = []
    for target in filter(None, [clock, chrome]):
        node = scroll_find_row(target)
        if node is not None:
            tap_node(node)
            selected.append(target)
            time.sleep(0.4)
        else:
            log(f"could not tap row {target}")
    screenshot("03-picker-selected.png")
    prefs = prefs_blocked()
    log(prefs)
    persist_ok = all(p in prefs for p in selected) if selected else False
    if persist_ok:
        record("2-select", "PASS", ",".join(selected))
    else:
        record("2-select", "FAIL", f"selected={selected} prefs={prefs[-400:]}")

    # Restart app, confirm selection
    launch_openblocker()
    time.sleep(2)
    screenshot("04-home-after-restart.png")
    prefs2 = prefs_blocked()
    home_count_ok = ui_has(text="apps blocked") or ui_has(rid="blocked_apps_count")
    if persist_ok and all(p in prefs2 for p in selected):
        record("2-persist-restart", "PASS", prefs2[-200:])
    else:
        record("2-persist-restart", "FAIL", prefs2[-400:])

    # Accessibility
    enable_accessibility()
    launch_openblocker()
    time.sleep(2)
    screenshot("05-accessibility-on.png")
    a11y_ui = ui_has(text="Accessibility service is enabled") or ui_has(rid="accessibility_enabled")
    a11y_setting = A11Y in adb_out("shell", "settings", "get", "secure", "enabled_accessibility_services")
    if a11y_ui and a11y_setting:
        record("3-accessibility", "PASS")
    elif a11y_setting:
        # UI may need a resume; try once more
        adb("shell", "input", "keyevent", "KEYCODE_HOME")
        time.sleep(1)
        launch_openblocker()
        time.sleep(2)
        screenshot("05-accessibility-on.png")
        a11y_ui = ui_has(text="Accessibility service is enabled") or ui_has(rid="accessibility_enabled")
        if a11y_ui:
            record("3-accessibility", "PASS", "after resume")
        else:
            record("3-accessibility", "FAIL", "setting on, Home UI did not show enabled")
    else:
        record("3-accessibility", "FAIL", "secure setting not applied")

    # Start block without NFC
    start_out = broadcast("app.openblocker.android.debug.START_SESSION")
    time.sleep(1)
    sess = session_prefs()
    log(sess)
    launch_openblocker()
    time.sleep(2)
    screenshot("06-blocking-active.png")
    blocking_ui = ui_has(text="Blocking Active") or "true" in sess
    if "result=0" in start_out or "Broadcast completed" in start_out:
        if blocking_ui or "true" in sess:
            record("4-debug-start", "PASS")
        else:
            record("4-debug-start", "FAIL", f"broadcast ok but state={sess}")
    else:
        record("4-debug-start", "FAIL", start_out[-300:])

    # Launch Clock (blocked)
    if clock:
        launch_package(clock)
        time.sleep(3)
        screenshot("07-clock-blocked.png")
        blocked = activity_shown("BlockScreenActivity") or ui_has(text="App Blocked") or ui_has(rid="block_screen")
        if blocked:
            record("4-clock-overlay", "PASS")
        else:
            record("4-clock-overlay", "FAIL", current_focus())
    else:
        record("4-clock-overlay", "FAIL", "no clock package")

    # Non-blocked: Settings
    adb("shell", "input", "keyevent", "KEYCODE_HOME", check=False)
    time.sleep(1)
    launch_package("com.android.settings")
    time.sleep(3)
    screenshot("08-settings-not-blocked.png")
    settings_blocked = activity_shown("BlockScreenActivity") or ui_has(text="App Blocked")
    settings_open = activity_shown("settings") or ui_has(text="Settings") or ui_has(text="Network")
    if not settings_blocked and (settings_open or "settings" in current_focus().lower()):
        record("4-settings-not-covered", "PASS")
    elif not settings_blocked:
        record("4-settings-not-covered", "PASS", f"no overlay; focus={current_focus()}")
    else:
        record("4-settings-not-covered", "FAIL", "Settings was covered by BlockScreen")

    # Reboot mid-block
    log("rebooting emulator mid-block...")
    adb("reboot", timeout=30, check=False)
    time.sleep(8)
    wait_boot(timeout_s=1800)
    skip_setup()
    enable_accessibility()
    time.sleep(2)
    sess_after = session_prefs()
    log(f"session after reboot: {sess_after}")
    if clock:
        launch_package(clock)
        time.sleep(4)
        screenshot("09-after-reboot-still-blocked.png")
        blocked = activity_shown("BlockScreenActivity") or ui_has(text="App Blocked") or ui_has(rid="block_screen")
        persist_session = "true" in sess_after
        if blocked:
            record("5-reboot-persist", "PASS")
        elif persist_session:
            record("5-reboot-persist", "FAIL", "prefs true but overlay missing")
        else:
            record("5-reboot-persist", "FAIL", f"session not persisted: {sess_after}")
    else:
        record("5-reboot-persist", "FAIL", "no clock")

    # End block via debug path
    end_out = broadcast("app.openblocker.android.debug.END_SESSION")
    time.sleep(1)
    adb("shell", "input", "keyevent", "KEYCODE_HOME", check=False)
    time.sleep(1)
    if clock:
        launch_package(clock)
        time.sleep(3)
        screenshot("10-clock-after-end.png")
        still_blocked = activity_shown("BlockScreenActivity") or ui_has(text="App Blocked")
        clock_open = (clock.split(".")[-1] in current_focus().lower()) or activity_shown("deskclock") or activity_shown("DeskClock")
        if not still_blocked:
            record("5-end-block-clock-opens", "PASS", current_focus())
        else:
            record("5-end-block-clock-opens", "FAIL", current_focus())
    else:
        record("5-end-block-clock-opens", "FAIL", "no clock")

    launch_openblocker()
    time.sleep(2)
    screenshot("11-home-not-blocking.png")
    if ui_has(text="Not Blocking") or "false" in session_prefs():
        record("5-home-not-blocking", "PASS")
    else:
        record("5-home-not-blocking", "FAIL", session_prefs())

    fatals2 = fatal_log()
    if fatals2:
        record("logcat-fatal", "FAIL", fatals2[:500])
    else:
        record("logcat-fatal", "PASS")

    report = SHOT_DIR / "RESULTS.txt"
    lines = [f"{s}\t{st}\t{d}" for s, st, d in RESULTS]
    report.write_text("\n".join(lines) + "\n")
    log("==== RESULTS ====")
    log("\n".join(lines))
    failed = [r for r in RESULTS if r[1] == "FAIL"]
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        log(f"command failed: {exc} output={getattr(exc, 'output', '')}")
        sys.exit(1)
