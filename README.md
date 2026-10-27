# Open Blocker

Open Blocker is a free, open source physical phone blocker. You pick apps to lock, and they stay locked until you scan your key. The idea is friction: you walk to the key, you do not swipe a toggle.

The iPhone app is on the [App Store](https://apps.apple.com/app/id6824046126).

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/app/id6824046126)

Your key can be:

- **iPhone:** an NFC tag or sticker, many NFC cards you already carry, a printed QR code, or a barcode (for example the one on a book).
- **Android:** an NFC tag, an NFC card, or a printed Open Blocker QR code. No barcodes yet.

**License:** MIT  
**iPhone:** 1.0.0 is on the [App Store](https://apps.apple.com/app/id6824046126) (live as of Oct 26, 2026). Tested on a real iPhone.  
**Android:** 0.2.0-alpha APK on [GitHub Releases](https://github.com/fjenn/open-blocker/releases/tag/v0.2.0-alpha). Coming to Google Play. Tested on an emulator only. Real-phone NFC testing is still pending.  
**Privacy:** https://openblocker.org/privacy · **Terms:** https://openblocker.org/terms

## Android alpha (emulator only so far)

Download `openblocker-0.2.0-alpha.apk` from [Releases](../../releases). Check the SHA-256 next to the file.

**0.2.0-alpha is an early alpha and is not a daily-driver release.** If you install it, you are helping test. Please report what happens (success or failure) in [Issues](../../issues) or [Discussions](../../discussions).

This alpha has been run on an API 34 Android emulator (home, app picker, Accessibility, block overlay, QR registration / camera permission / scanner preview). It has **not** been tested on a wide range of real phones. NFC tag write/read, pairing a real card, scanning a real printed QR to start or end a session, and wrong-key reject on hardware are **unverified**.

### Installing the Android alpha

This alpha is not on Google Play yet (coming to Google Play). Google Play Protect does not recognise it and may warn about it or block it. On a Samsung test phone, opening the APK from WhatsApp showed "App not installed", Play Protect blocked it, and tapping "Install anyway" still failed. The steps below are what to try. Menu names vary a little between Android versions and phone makers.

**Only install the APK from the official [v0.2.0-alpha release page](https://github.com/fjenn/open-blocker/releases/tag/v0.2.0-alpha).** Do not install a copy forwarded to you in a chat app. Check the SHA-256 before installing. This is an early alpha.

1. On the phone, open the [release page](https://github.com/fjenn/open-blocker/releases/tag/v0.2.0-alpha) in your browser and download `openblocker-0.2.0-alpha.apk`. Download it directly rather than opening a copy from WhatsApp or another messaging app.
2. Verify the file. Its SHA-256 must match the value in `openblocker-0.2.0-alpha.apk.sha256` on the same release page. On a computer: `shasum -a 256 openblocker-0.2.0-alpha.apk` (macOS) or `sha256sum openblocker-0.2.0-alpha.apk` (Linux). If it does not match, delete the file and do not install it.
3. Allow the app you open the APK with (your browser, or the Files / My Files app) to install unknown apps: Settings > Apps > [that app] > Install unknown apps > Allow.
4. If an older Open Blocker build (for example a debug build) is already on the phone, uninstall it first. Android will not install over an app signed with a different key and reports that as "App not installed" too.
5. Open the APK and tap Install.
6. If Play Protect blocks it, tap "More details", then "Install anyway".
7. If it still fails, temporarily turn off Play Protect scanning: open the Play Store, tap your profile picture, then Play Protect, then the settings gear, and turn off "Scan apps with Play Protect". Install the APK, then turn "Scan apps with Play Protect" back on right away.

If none of this works on your phone, please open an issue with the phone model, Android version, and the exact message you saw.

### Try it (testers)

1. Install the APK (see "Installing the Android alpha" above).
2. **Android 13+:** Settings > Apps > Open Blocker > Allow restricted settings.
3. Open Open Blocker and enable the Accessibility service.
4. Pick apps to block.
5. Pair a key: write or tap an NFC tag, or generate / scan a printed QR (`openblocker://tag/v1/` plus 32 lowercase hex characters).
6. Starting and ending a session with that key on a real phone is the test. Please file what you see.

**Minimum Android:** 7.0 (API 24)

A determined person can get around the Android block (safe mode, uninstall, turning off Accessibility, ADB). This is friction for people who want to focus, not a lock. NFC tags and QR codes can be copied. There is no anti-clone claim.

Not every card works. Test yours.

## Open tag spec

The tag format is documented in [spec/SPEC.md](spec/SPEC.md): NDEF external type `openblocker.org:tag`, 16-byte random ID, optional Android Application Record. QR encoding is the same ID as `openblocker://tag/v1/{32 hex}`, error correction H. Any app can implement it.

From reading Foqos's code, the same tag also works as your key in Foqos on iPhone (UID matching). That has not been tested on an iPhone.

## Printable key

No NFC hardware is required if you print a QR from the app. For a physical tag:

- NTAG213 sticker, 25 mm round
- Optional 10 x 2 mm disc magnet
- 3D case: [hardware/](hardware/) (`case.scad`, `openblocker-key-25mm.stl`). Print flat, no supports.

## iPhone

App source lives in `ios/`. Version 1.0.0 is on the [App Store](https://apps.apple.com/app/id6824046126). Apple approved the Family Controls (Distribution) entitlement. It has been tested on a real iPhone.

On iPhone, an NFC tag or sticker (NTAG213/215/216), many NFC cards, a printed QR code, or a barcode works as a key. Cards with a changing ID (many bank cards and phone wallets) are rejected on purpose.

## Privacy

No account, no ads, no tracking. Your keys, app choices and settings stay on your phone.

**Share anonymous count:**

- **iPhone (1.0.0):** on by default. You can turn it off in Settings. After each completed block (ended by your key, a schedule end, or a passage window) it sends a random install ID, the event name `block_completed`, a random event ID, the app version, and the platform. Emergency unblocks and lost Screen Time access are not sent. No app names or usage data. Used only to count how many people completed at least one block and how many blocks were completed in total.
- **Android (0.2.0-alpha on GitHub Releases):** the setting is also on by default. The released APK is built without a count server URL, so it sends nothing. Current source sends one `first_block` ping only if you build with `OPENBLOCKER_COUNT_URL`.

Full policy: https://openblocker.org/privacy

## Build from source

```bash
cd android
./gradlew test assembleRelease
```

A signed GitHub Release APK needs `OPENBLOCKER_KEYSTORE_*` (see [RELEASE.md](RELEASE.md)). Do not commit a keystore.

Tag format tests: `cd spec/reference && ./gradlew test`

## Credits

Builds on ideas from [Brick](https://getbrick.com), [Foqos](https://foqos.app) (MIT), [Lock](https://github.com/NathanLenias/lock-app), [nfcGuard](https://github.com/Andebugulin/nfcGuard), and [TapBlok](https://github.com/cajdata/TapBlok). iOS code adapted from Foqos, Careful, and TapBack is listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Android QR uses ZXing (Apache 2.0).
