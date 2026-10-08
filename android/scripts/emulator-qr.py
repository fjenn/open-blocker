#!/usr/bin/env python3
"""Open QR registration, permission, and scanner on the emulator. Saves qr-*.png."""

from __future__ import annotations

import importlib.util
import sys
import time
from pathlib import Path

_VERIFY = Path(__file__).resolve().parent / "emulator-verify.py"
_spec = importlib.util.spec_from_file_location("emulator_verify", _VERIFY)
_mod = importlib.util.module_from_spec(_spec)
assert _spec is not None and _spec.loader is not None
_spec.loader.exec_module(_mod)

adb = _mod.adb
current_focus = _mod.current_focus
log = _mod.log
screenshot = _mod.screenshot
skip_setup = _mod.skip_setup
tap_res = _mod.tap_res
tap_text = _mod.tap_text
wait_boot = _mod.wait_boot
PKG = _mod.PKG
MAIN = _mod.MAIN
APK = _mod.APK
SHOT_DIR = _mod.SHOT_DIR


def revoke_camera() -> None:
    adb("shell", "pm", "revoke", PKG, "android.permission.CAMERA", check=False)


def grant_camera() -> None:
    adb("shell", "pm", "grant", PKG, "android.permission.CAMERA", check=False)


def launch() -> None:
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
    time.sleep(4)


def wait_focus(fragment: str, seconds: int = 20) -> bool:
    deadline = time.time() + seconds
    last = ""
    while time.time() < deadline:
        last = current_focus()
        if fragment in last:
            log(f"focus ok {last}")
            return True
        time.sleep(1)
    log(f"focus timeout wanted={fragment} last={last}")
    return False


def open_qr_screen() -> None:
    adb("shell", "input", "swipe", "540", "1800", "540", "600", "400", check=False)
    time.sleep(1)
    if tap_res("add_qr_key") or tap_text("Add QR key"):
        time.sleep(2)
        return
    screenshot("qr-home-failed.png")
    raise SystemExit("Add QR key not found")


def main() -> int:
    wait_boot()
    skip_setup()
    if not Path(APK).is_file():
        raise SystemExit(f"missing APK {APK}")
    adb("install", "-r", APK, timeout=180)
    revoke_camera()
    launch()
    open_qr_screen()
    shot1 = screenshot("qr-registration.png")

    if not tap_res("scan_to_register") and not tap_text("Scan with camera"):
        screenshot("qr-scan-tap-failed.png")
        raise SystemExit("Scan with camera not found")
    wait_focus("GrantPermissionsActivity") or wait_focus("QrScanActivity")
    time.sleep(1)
    shot2 = screenshot("qr-permission.png")
    log(f"permission focus={current_focus()}")

    grant_camera()
    time.sleep(1)
    if "QrScanActivity" not in current_focus():
        adb("shell", "input", "keyevent", "KEYCODE_BACK", check=False)
        time.sleep(1)
        launch()
        open_qr_screen()
        tap_res("scan_to_register") or tap_text("Scan with camera")
    wait_focus("QrScanActivity", seconds=25)
    time.sleep(2)
    shot3 = screenshot("qr-scanner.png")
    log(f"scanner focus={current_focus()}")

    log(f"saved {shot1}")
    log(f"saved {shot2}")
    log(f"saved {shot3}")
    log(f"SHOT_DIR={SHOT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
