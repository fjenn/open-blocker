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

## Installing the Android alpha

This alpha is not on Google Play yet, so Google Play Protect does not recognise it and may warn about it or block it. On a Samsung test phone, opening the APK from WhatsApp showed "App not installed", Play Protect blocked it, and tapping "Install anyway" still failed. The steps below are what to try. Menu names vary a little between Android versions and phone makers.

**Only install the APK from the official [v0.1.0-alpha release page](https://github.com/fjenn/open-blocker/releases/tag/v0.1.0-alpha).** Do not install a copy forwarded to you in a chat app. Check the SHA-256 before installing. This is an early alpha and has not had a security review.

1. On the phone, open the [release page](https://github.com/fjenn/open-blocker/releases/tag/v0.1.0-alpha) in your browser and download `open-blocker-0.1.0-alpha.apk`. Download it directly rather than opening a copy from WhatsApp or another messaging app.
2. Verify the file. Its SHA-256 must match the value in `open-blocker-0.1.0-alpha.apk.sha256` on the same release page. On a computer: `shasum -a 256 open-blocker-0.1.0-alpha.apk` (macOS) or `sha256sum open-blocker-0.1.0-alpha.apk` (Linux). If it does not match, delete the file and do not install it.
3. Allow the app you open the APK with (your browser, or the Files / My Files app) to install unknown apps: Settings > Apps > [that app] > Install unknown apps > Allow.
4. If an older Open Blocker build (for example a debug build) is already on the phone, uninstall it first. Android will not install over an app signed with a different key and reports that as "App not installed" too.
5. Open the APK and tap Install.
6. If Play Protect blocks it, tap "More details", then "Install anyway".
7. If it still fails, temporarily turn off Play Protect scanning: open the Play Store, tap your profile picture, then Play Protect, then the settings gear, and turn off "Scan apps with Play Protect". Install the APK, then turn "Scan apps with Play Protect" back on right away.

If none of this works on your phone, please open an issue with the phone model, Android version, and the exact message you saw.
