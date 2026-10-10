# Changelog

## 0.2.0-alpha (2026-10-10)

**Early alpha. Tested on an emulator only.** NFC is not yet proven on a real phone.

### Android

- Matches the iPhone design and flows
- Website blocking in Chrome, Samsung Internet, Firefox, Brave, Edge, Opera, DuckDuckGo, and Vivaldi through Accessibility
- 3D key, hold-to-block with haptics, QR or NFC keys
- Sideload APK `open-blocker-0.2.0-alpha.apk` (`versionCode` 2)

## 0.1.0-alpha (2026-10-08)

**Early alpha. Not yet tested on real devices.** NFC keys and printed QR keys have been exercised on an Android emulator only. Please report tester results in Issues or Discussions.

### Android

- Sideload APK: pick apps, Accessibility overlay, NFC pair/write, printed QR generate/scan
- Same QR URI as iOS: `openblocker://tag/v1/{32 lowercase hex}`
- Camera permission only at scan time (ZXing, no Play services)
- Release-signed APK `open-blocker-0.1.0-alpha.apk`

### Spec and hardware

- Open NDEF tag spec and QR encoding in `spec/`
- 25 mm NTAG213 case STL, no supports, optional 10x2 mm magnet pocket

### iPhone

- Source in `ios/` (not shipped as an App Store binary in this release)
