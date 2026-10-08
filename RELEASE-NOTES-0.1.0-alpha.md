# Open Blocker 0.1.0-alpha

**Early alpha. Not yet tested on real devices.** Both NFC keys and printed QR keys have been tried only on an Android emulator. This is not a "it is ready, go use it" release. If you install the APK, please report results (what phone, what key, what happened) in GitHub Issues or Discussions.

## What this is

An open source physical phone blocker. You choose apps, then start or stop a session by tapping an NFC tag or scanning a printed QR.

## Android APK

File: `open-blocker-0.1.0-alpha.apk` (also attached as `openblocker-0.1.0-alpha.apk` from CI)

- Sideload: allow unknown sources, install, enable Accessibility, pair a key.
- Android 13+: Allow restricted settings for this app before Accessibility will stick.
- SHA-256: `2460b308f76911b8e6986073efc5e0a9703563c7b75b81ad0705e0363a8462d9`

Emulator so far: home, app picker, Accessibility, block overlay, QR registration screen, camera permission prompt, scanner preview. **Not proven on hardware:** NFC write/read, real printed QR start/end/wrong-QR, card pairing, a range of phone models.

## iPhone

Source is in `ios/`. No App Store build in this release. Screen Time / Family Controls distribution approval is still pending. Waitlist: https://openblocker.vercel.app/waitlist

## Also in this tag

- Open tag spec (`spec/SPEC.md`) and Kotlin reference tests
- Printable 25 mm NTAG213 case STL (`hardware/`)
- Optional anonymous "Count me" ping (off unless you build with a count URL)

## Honesty

NFC and QR keys are not security. They can be copied. On Android the block can be bypassed (safe mode, uninstall, Accessibility off, ADB). Not every NFC card works. Test yours.
