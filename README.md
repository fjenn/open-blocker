# Open Blocker

**0.1.0-alpha is an early alpha. It has not been tested on real devices.** Both NFC keys and printed QR keys have been tried only on an Android emulator. This is not a daily-driver release. If you install it, you are helping test. Please report what happens (success or failure) in [Issues](../../issues) or [Discussions](../../discussions).

Open Blocker is an open source physical phone blocker. You pick apps to lock, then start or stop a session by tapping an NFC key or scanning a printed QR. The idea is friction: you walk to the key, you do not swipe a toggle.

**License:** MIT  
**Android:** 0.1.0-alpha (sideload APK)  
**iPhone:** source is in `ios/`. There is no App Store build yet. Apple Screen Time / Family Controls distribution approval is still pending. Join the waitlist: https://openblocker.vercel.app/waitlist

## Android alpha (emulator only so far)

Download `open-blocker-0.1.0-alpha.apk` from [Releases](../../releases). Check the SHA-256 next to the file.

This alpha has been run on an API 34 Android emulator (home, app picker, Accessibility, block overlay, QR registration / camera permission / scanner preview). It has **not** been tested on a wide range of real phones. NFC tag write/read, pairing a real card, scanning a real printed QR to start or end a session, and wrong-key reject on hardware are **unverified**.

### Try it (testers)

1. Allow install from unknown sources, then install the APK.
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

App source lives in `ios/`. The App Store version is waiting on Apple's Screen Time (Family Controls distribution) approval. Join the waitlist: https://openblocker.vercel.app/waitlist

## Privacy

Nothing leaves the device unless you turn on the optional "Count me" ping. See [PRIVACY.md](PRIVACY.md).

## Build from source

```bash
cd android
./gradlew test assembleRelease
```

A signed GitHub Release APK needs `OPENBLOCKER_KEYSTORE_*` (see [RELEASE.md](RELEASE.md)). Do not commit a keystore.

Tag format tests: `cd spec/reference && ./gradlew test`

## Credits

Builds on ideas from [Brick](https://getbrick.com), [Foqos](https://foqos.app) (MIT), [Lock](https://github.com/NathanLenias/lock-app), [nfcGuard](https://github.com/Andebugulin/nfcGuard), and [TapBlok](https://github.com/cajdata/TapBlok). iOS code adapted from Foqos, Careful, and TapBack is listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Android QR uses ZXing (Apache 2.0).
