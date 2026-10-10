# Open Blocker 0.2.0-alpha

**Early alpha. Tested on an emulator only.** NFC is not yet proven on a real phone. If you install the APK, please report what happens in GitHub Issues or Discussions.

## What's new

Android now matches the iPhone design and flows.

- Website blocking in Chrome, Samsung Internet, Firefox, Brave, Edge, Opera, DuckDuckGo, and Vivaldi through Accessibility
- The 3D key on the home screen
- Hold to block, with haptics
- QR keys or NFC keys

## Android APK

File: `open-blocker-0.2.0-alpha.apk` (CI also attaches `openblocker-0.2.0-alpha.apk`)

SHA-256 is in `open-blocker-0.2.0-alpha.apk.sha256` on this release page. It will be copied into these notes after the signed APK is published.

This build has been run on an Android emulator. It has not been tested on a real phone. NFC write, tap, and pairing on hardware are unverified.

## Install

This alpha is not on Google Play. Allow installs from unknown sources. Play Protect may warn about it or block it.

**Only install the APK from the official [v0.2.0-alpha release page](https://github.com/fjenn/open-blocker/releases/tag/v0.2.0-alpha).** Do not install a copy forwarded to you in a chat app. Check the SHA-256 before installing.

1. Allow the app you open the APK with (your browser, or the Files / My Files app) to install unknown apps: Settings > Apps > [that app] > Install unknown apps > Allow.
2. On the phone, open the [release page](https://github.com/fjenn/open-blocker/releases/tag/v0.2.0-alpha) in your browser and download `open-blocker-0.2.0-alpha.apk`. Download it directly rather than opening a copy from WhatsApp or another messaging app.
3. Verify the file. Its SHA-256 must match the value in `open-blocker-0.2.0-alpha.apk.sha256` on the same release page. On a computer: `shasum -a 256 open-blocker-0.2.0-alpha.apk` (macOS) or `sha256sum open-blocker-0.2.0-alpha.apk` (Linux). If it does not match, delete the file and do not install it.
4. If an older Open Blocker build is already on the phone, uninstall it before installing this one. Android will not install over an app signed with a different key and reports that as "App not installed" too.
5. Open the APK and tap Install.
6. If Play Protect warns or blocks it, tap "More details", then "Install anyway".
7. Android 13+: Settings > Apps > Open Blocker > Allow restricted settings.
8. Open the app and enable the Accessibility service. Pick apps or sites to block, then pair a key.

If none of this works on your phone, please open an issue with the phone model, Android version, and the exact message you saw.

## Honesty

A determined person can get around the Android block (safe mode, uninstall, turning off Accessibility, ADB). This is friction for people who want to focus, not a lock.

Not every card works. Test yours.
