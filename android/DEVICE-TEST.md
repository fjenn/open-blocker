# Android device test

**0.1.0-alpha is an early alpha, not tested on real devices.** NFC keys and QR keys have been tried on an Android emulator only. This checklist is how to test on a phone. Please report Pass/Fail in GitHub Issues or Discussions.

Two tracks: an **emulator pass** for everything except NFC and real-camera QR, and a **physical phone** pass for NFC plus printed-QR register / start / end / wrong-QR.

The public file is `artifacts/release/open-blocker-0.1.0-alpha.apk` (release-signed). Debug APKs are for emulator work only.

Mark each row **Pass** or **Fail**.

## Emulator-verified (API 34 google_apis x86_64)

Run on a headless AVD (`-no-window -no-audio -gpu swiftshader_indirect`). Script: `android/scripts/emulator-verify.py`. Screenshots: `artifacts/android-emulator/`.

On this host `/dev/kvm` exists but KVM vCPU create faults, so the AVD was booted with TCG (`-accel off`). First boot is slow.

| Step | Action | Expected | Result |
|------|--------|----------|--------|
| E1 | Install debug APK, `am start` MainActivity | Home shows "Not Blocking"; logcat has no Open Blocker `FATAL EXCEPTION` | **Pass** (`01-home.png`) |
| E2 | Manage Blocked Apps | Launchable apps include Chrome, Clock, and Settings | **Pass** (`02-app-picker.png`, `02-app-picker-settings.png`, `03-picker-selected.png`) |
| E3 | Check Clock and Chrome, restart the app | Home "Blocked Apps" shows "2 apps blocked"; prefs keep those packages | **Pass** (`04-home-after-restart.png`) |
| E4 | `appops set … ACCESS_RESTRICTED_SETTINGS allow`; `settings put secure enabled_accessibility_services app.openblocker.android/app.openblocker.android.service.AppBlockingService`; toggle `accessibility_enabled` 0 then 1 | Home shows "Accessibility service is enabled"; `dumpsys accessibility` Bound services lists Open Blocker | **Pass** (`05-accessibility-on.png`) |
| E5 | `am broadcast -a app.openblocker.android.debug.START_SESSION -n app.openblocker.android/.debug.DebugSessionReceiver` (debug APK only) | Home shows "Blocking Active" | **Pass** (`06-blocking-active.png`) |
| E6 | Launch Clock | `BlockScreenActivity` covers it ("App Blocked") | **Pass** (`07-clock-blocked.png`) |
| E7 | Launch Settings (not in the blocked set) | Settings opens; no overlay | **Pass** (`08-settings-not-blocked.png`) |
| E8 | `END_SESSION` debug broadcast, launch Clock | Clock opens normally | **Pass** (`10-clock-after-end.png`, `11-home-not-blocking.png`) |
| E9 | Start a block, `adb reboot`, wait for boot, re-bind Accessibility, launch Clock | `session_prefs` still `is_blocking=true`; overlay still covers Clock | **Pass** (`09-after-reboot-still-blocked.png`) |
| E10 | Inspect release APK / `DebugHookNotInReleaseTest` | `DebugSessionReceiver` and `START_SESSION` are absent from release; present in debug | **Pass** |
| E11 | Home > Add QR key | Printed QR key screen (generate / share / scan) | **Pass** (`qr-registration.png`) |
| E12 | Scan with camera (CAMERA not pre-granted) | System camera permission prompt | **Pass** (`qr-permission.png`) |
| E13 | Allow camera | Scanner preview (`QrScanActivity`) with no crash | **Pass** (`qr-scanner.png`) |

Do not `am force-stop` after enabling Accessibility: that unbinds the service. The debug receiver is compiled only from `android/app/src/debug/` and is not merged into release.

E11-E13 prove the QR UI and permission path on the emulator virtual camera. They do not prove decoding a printed QR or start/end/wrong-QR on a real camera.

## Physical phone (NFC). Not run in this environment.

Use a real Android phone with NFC. Fill these boxes on the phone.

### What you need

- Android 7.0 or newer phone with NFC turned on
- One writable NFC tag (NTAG213/215/216) **or** a transit card / hotel key / work badge
- The APK file and a USB cable or a way to sideload it
- A second NFC tag or card that you will **not** pair (for the wrong-key check)
- A way to print or display an Open Blocker QR (`openblocker://tag/v1/` plus 32 hex chars). You can generate one in the app, or print one from iPhone. Also have a different QR (any unrelated code, or another generated Open Blocker QR you did not register) for the wrong-key check.

### 1. Sideload

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 1.1 | Install the APK (`adb install -r` or open the file on the phone) | App appears as Open Blocker | |
| 1.2 | Open Open Blocker | Home shows "Not Blocking" | emulator-verified; re-check on phone |
| 1.3 | **Android 13+ only:** Settings > Apps > Open Blocker > Allow restricted settings | Restricted settings allowed | emulator used `appops ACCESS_RESTRICTED_SETTINGS allow` |

### 2. Accessibility service

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 2.1 | Tap "Open Accessibility Settings", enable Open Blocker | System warning appears; you allow it | **needs phone UI** (emulator used `settings put`) |
| 2.2 | Return to Open Blocker | Home shows "Accessibility service is enabled" in green | emulator-verified via `settings put` |

### 3. Pick apps

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 3.1 | Tap "Manage Blocked Apps" | A list of launchable apps (Chrome, Calculator, Clock included if they have a launcher icon) | emulator-verified |
| 3.2 | Check two apps you can open quickly | Checkboxes fill | emulator-verified |
| 3.3 | Go back | Home "Blocked Apps" card shows "2 apps blocked" | emulator-verified |

### 4. Pair a key

Do **one** of 4A, 4B, or 4C. 4A/4B need a physical phone and real tags. 4C needs a real camera (print or another screen).

**4A. Write an Open Blocker tag**

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 4A.1 | Pair NFC Tag > Write Tag, hold the tag to the phone | "Tag written and paired successfully" | **needs phone** |
| 4A.2 | Home NFC card | Shows at least 1 paired key | **needs phone** |

**4B. Any card (transit / hotel / badge)**

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 4B.1 | Pair NFC Tag > Pair Any Card > Start Pairing, tap the card | "Tap 2 of 2" | **needs phone** |
| 4B.2 | Tap the same card again | "Card Paired!" | **needs phone** |
| 4B.3 | If the card is rejected as random (0x08) or the two taps differ | That card cannot be a key. Not every card works. Test yours. | **needs phone** |

**4C. Printed QR key (needs a real camera)**

Print a QR, or show it on another screen. Generate in Open Blocker (Generate QR Code, then Share or print) or use one printed from iPhone. Format: `openblocker://tag/v1/{32 lowercase hex chars}`.

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 4C.1 | Home > Add QR key | Printed QR key screen | emulator-verified UI (`qr-registration.png`); re-check on phone |
| 4C.2 | Tap Generate QR Code | QR image appears; toast that the key is saved | **needs phone** (or skip if you will scan an iPhone-printed QR) |
| 4C.3 | Share or print, then keep the paper/screen across the room | You have a physical QR to walk to | **needs phone / printer** |
| 4C.4 | Or: Scan with camera and point at an already printed Open Blocker QR | Camera permission once; then scanner; toast that the QR key is saved. Deny: Settings / Cancel, no crash | permission+scanner UI emulator-verified; **register on phone** |
| 4C.5 | Home NFC/QR cards | Paired key count includes the QR | **needs phone** |

### 5. Start a block, overlay, stop

Session start/stop without a physical key is emulator-verified via the debug broadcast. On the phone, use the paired tag or the paired QR.

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 5.1 | On home, tap the paired tag or card, **or** tap Scan QR to start or stop and scan the paired QR | Toast "Blocking session started"; home shows "Blocking Active" | **needs phone NFC or camera** (emulator used debug START_SESSION) |
| 5.2 | Open a blocked app | Full-screen "App Blocked" overlay (`BlockScreenActivity`) | emulator-verified for Clock |
| 5.3 | Tap the **same** paired NFC key, **or** tap Scan QR key on the overlay and scan the same paired QR | Overlay closes; toast "Blocking session ended"; home shows "Not Blocking" | **needs phone NFC or camera** (emulator used debug END_SESSION) |
| 5.4 | Open the blocked app again | App opens normally (session is over) | emulator-verified for Clock |

### 6. Wrong key

**Needs a physical phone.** NFC: a second, unpaired tag. QR: an unrelated QR, or an Open Blocker QR you did not register. Cannot be proven on the emulator.

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 6.1 | Start a session with the paired key | Blocking Active | **needs phone** |
| 6.2 | Tap an unpaired tag or card, **or** scan a QR that is not the paired key | Toast "Wrong key..." (or "This QR is not an Open Blocker key." if the payload is not `openblocker://tag/v1/...`); session stays active | **needs phone** |
| 6.3 | Tap or scan the paired key | Session ends | **needs phone** |

### 7. Reboot persistence

| Step | Action | Expected | Pass/Fail |
|------|--------|----------|-----------|
| 7.1 | Start a session, then reboot the phone | After unlock, Open Blocker still has Accessibility on | emulator-verified (`adb reboot`); re-check on phone |
| 7.2 | Open a blocked app | "App Blocked" overlay still appears | emulator-verified |
| 7.3 | Tap the paired key | Session ends | **needs phone NFC** |

## Notes

- A determined user can get around the block on Android (safe mode, uninstall, turning off Accessibility, ADB). Open Blocker adds friction, not a lock.
- The public alpha APK is release-signed (`open-blocker-0.1.0-alpha.apk`). Debug APKs are for emulator work.
- NFC tag write, NDEF/UID read, and wrong-key reject on real tags cannot be proven without this phone run.
- Printed QR register, start block, end block (including from the overlay), and wrong-QR reject need a real camera and a printed (or on-screen) QR. The emulator only proved the registration screen, permission prompt, and scanner preview.
