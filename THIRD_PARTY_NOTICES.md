# Third-Party Code Attributions

Open Blocker includes code adapted from the following open-source projects:

## Foqos
- **Source:** https://github.com/awaseem/foqos
- **License:** MIT License
- **Copyright:** Copyright (c) 2024 Ali Waseem
- **Files adapted:**
  - `AppBlockerUtil.swift` - ManagedSettings shield application and clearing
  - `WeeklySessionAggregator.swift` - Session statistics aggregation
  - `NFCScannerUtil.swift` - NFC tag reading and NDEF write session
  - `QRCodeScanner.swift` - QR camera scanner (Open Blocker uses AVCaptureMetadataOutput instead of the CodeScanner package)
  - `DeviceActivityCenterUtil.swift` - DeviceActivity registration patterns
  - `RequestAuthorizer.swift` - FamilyControls authorization wrapper

## Careful
- **Source:** https://github.com/alexanderjmontague/careful-ios
- **License:** MIT License
- **Copyright:** Copyright (c) 2026 Alexander Montague
- **Files adapted:**
  - `CarefulBlocker.swift` - Idempotent `reconcile()` pattern and `scheduleRelock` timing
  - `CarefulModel.swift` - Midnight-crossing schedule window logic
  - `CarefulMonitorExtension.swift` - DeviceActivityMonitor extension structure

## TapBack
- **Source:** https://github.com/OGSarah/TapBack
- **License:** MIT License
- **Copyright:** Copyright (c) 2026 SarahUniverse
- **Files adapted:**
  - `NFCScannerProtocol.swift` - Async NFC scanner protocol
  - `CoreNFCScanner.swift` - CoreNFC async/await implementation
  - `MockNFCScanner.swift` - Mock scanner for testing and simulator

## ZXing (Android QR)

- **Source:** https://github.com/zxing/zxing and https://github.com/journeyapps/zxing-android-embedded
- **License:** Apache License 2.0
- **Use:** Encode and decode Open Blocker QR keys (`openblocker://tag/v1/{32 hex}`). `zxing-android-embedded` for the camera preview. No Google Play services.

Apache License 2.0: http://www.apache.org/licenses/LICENSE-2.0

---

## MIT License Text

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
