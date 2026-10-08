# Open Blocker Android App

**0.1.0-alpha is an early alpha, not tested on real devices.** NFC keys and printed QR keys have been tried on an Android emulator only. If you sideload the APK, please report results in GitHub Issues or Discussions.

Reference Android app for the Open Blocker tag spec.

## Features

- Block chosen apps during a session (Accessibility overlay)
- NFC pairing (write Open Blocker format, pair by UID, or two-tap any card)
- Printed QR keys (generate, share/print, or scan; `openblocker://tag/v1/{32 hex}`)
- Optional opt-in anonymous count ping (off unless built with a count URL and key)

## Requirements

- Android 7.0 (API 24) or higher
- NFC optional if you use a printed QR
- Camera optional; requested only when you scan a QR
- JDK 17 to build (AGP 8.2)

## Build

Debug:

```bash
./gradlew assembleDebug
```

Release-signed (needs the four `OPENBLOCKER_KEYSTORE_*` variables; never commit the keystore):

```bash
./build-release.sh --release-only
```

Public alpha file: `artifacts/release/open-blocker-0.1.0-alpha.apk`

CI on tag `v*` uses the same script and GitHub secrets (`OPENBLOCKER_KEYSTORE_BASE64`, password, alias `openblocker`, key password).

TEST_MODE APK (`./build-release.sh --test-only`) has a Quick Test button. Do not ship it.

## Architecture

Accessibility watches `TYPE_WINDOW_STATE_CHANGED` and shows `BlockScreenActivity`. A paired NFC tap or QR scan starts or ends the session through `KeyMatcher`. Unpaired keys are rejected. The block is friction, not a lock.

Not every card works. Test yours.

## Testing

- Unit tests: `./gradlew test`
- Phone checklist: [DEVICE-TEST.md](DEVICE-TEST.md)
- Longer script: [docs/TESTING.md](../docs/TESTING.md)
