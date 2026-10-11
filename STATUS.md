# Open Blocker Status

This is the only status document. Last updated: 2026-10-08 (card compatibility wording).

`FINN-REPORT.md`, `BUILD-SUMMARY.md`, and `PROGRESS.md` were deleted. They overclaimed ("production-ready", "95% match") and contradicted what is actually verified.

Device steps live in `ios/TEST-ON-IPHONE.md`. Simulator demo: double-click `run-demo.command`.

## Verified in the simulator

Built with `CODE_SIGNING_ALLOWED=NO` on iPhone 18 Pro (`55E47EC3-2AD7-4E0C-9649-377066331E60`) and for `generic/platform=iOS`.

- **Tests on `main`.** **41 tests passed, 0 failed** (40 unit in `OpenBlockerTests`, 1 UI `WalkthroughTests.testWalkthrough`). Walkthrough now opens Help, Contact, About, and Notifications. xcodebuild can hang after the UI test reports; the suite itself is green.
- **Compile and demo.** `-demo` seeds fixed weekday history (Wednesday is always 2h 43m) plus a finished 32-minute session today. The walkthrough drives one session: idle home, mock NFC block, tabs, My Keys / Add Key, My Rules, Help / Contact / About / Notifications, Modes plus Edit, mock NFC unlock back to idle, then emergency 5 to 4.
- **NFC registration path.** Setup calls `appState.nfcScanner.scan()`. Simulator uses `MockNFCScanner` (stable UID `04a1b2c3d4e5f6` by default). Cards require two matching UIDs. Rotating UIDs are rejected. Demo Desk Key secret is the mock UID so a simulator tap matches.
- **QR path.** Generated keys use `OpenBlockerFormat.encodeForQR`. Block tab routes through `KeyScanner` (NFC, QR, or chooser). Simulator QR UI is a paste field because there is no camera.
- **Entitlements.** App: Family Controls, App Group `group.org.openblocker.OpenBlocker`, NFC formats TAG+NDEF. Monitor: Family Controls and the App Group. Info.plist has NFC and camera usage strings plus ISO7816 AID `D2760000850101`.
- **Emergency Unblocks.** Centered large remaining count, what it does, the 30-day refill, and an ink-filled destructive "Use an emergency unblock". Pushed Settings screens (Keys, Emergency, Rules, Help, Contact, About, Notifications) hide the custom tab bar. Confirm is in-screen (Cancel / Use). Unsigned simulator Keychain writes fail, so count persists in UserDefaults (`org.openblocker.emergency.`) as a fallback. UI test asserts 5 left, then 4 left after Use, then home idle.
- **Schedules.** Demo Work Hours is on and shows a next-run line; Evening Focus is off and shows "Off" instead of a next run. Rows still have Mon-Sun day chips, the time range, and the mode name. Recapture: `review/02-schedules.png`.
- **Walkthrough video.** Recorded during `WalkthroughTests.testWalkthrough` (Help, Contact, About, Notifications). After unlock, home is idle with an empty key.
- **Review screenshots.** Recaptured 2026-10-08 07:18 `12-help.png` (card compatibility wording). Earlier same morning 07:01: `03-activity.png`, `04-settings.png`, `07-emergency-unblock.png`, `13-about.png`, `dark-activity.png`, `dark-settings.png`. Activity Today is 32m / 1 session. Emergency has no tab bar.
- **Cold-start `run-demo.command`.** 2026-10-08 07:05 ART. `xcrun simctl shutdown all`, then deleted `ios/build`. Ran `run-demo.command`. **19.1 s** until "App launched" with `-demo`.
- **Settings actions.** Help is an in-app FAQ. About shows version 1.0.0 (1), MIT, and the project page. Contact opens the project page (`https://openblocker.vercel.app`). Notifications requests permission and posts a local alert when a block or schedule ends. Privacy still opens the site.
- **Dark mode.** Before the palette, `simctl ui booted appearance dark` left the greige canvas locked light. Tab labels used `.primary` (light in dark) on `Color(white: 0.97)`, so Block/Schedule/Activity/Settings were almost invisible. After `BrickTheme` light/dark tokens, canvas, cards, ink, tab bar, and the 3D key clay follow the scheme. Chart Y-axis ticks use `brickSecondaryLabel`. Settings row icons use the same ink and medium weight as the titles. Shots: `review/dark-home-idle.png`, `dark-home-blocked.png`, `dark-activity.png`, `dark-settings.png`.
- **Dynamic Type.** First XXL capture did not grow type (fixed `Font.system(size:)`). Home and Settings now use `@ScaledMetric` via `brickText`. At `content_size extra-extra-large`, labels are larger; no truncation or overlap on those two screens. Shots: `review/xxl-home.png`, `xxl-settings.png`. Appearance reset to light; content size reset to large.
- **App icon.** `ios/OpenBlocker/Resources/Assets.xcassets` AppIcon uses the single 1024 image from the CAD top render (`AppIcon-1024.png`, opaque RGB). `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Visible on the simulator home screen: `review/11-app-icon-springboard.png`.
- **First run (no `-demo`).** Uninstalled, relaunched without demo args. Onboarding asks for Screen Time; the simulator failure is shown in-place. Page dots use a darker, wider current-page capsule on all three pages. Empty home invites "Add a key". Shots: `review/first-run-onboarding-welcome.png`, `first-run-onboarding-screentime.png`, `first-run-onboarding-screentime-result.png`, `first-run-onboarding-key.png`, `first-run-home.png`, `first-run-schedules.png`, `first-run-activity.png`, `first-run-keys.png`.

## Needs a real iPhone

None of these has been run on hardware. Use `ios/TEST-ON-IPHONE.md`.

- **Family Controls authorization** and **ManagedSettings shields**. `BlockEngine` is a no-op in the simulator.
- **CoreNFC.** Tag UID, optional NDEF write, and two-tap card confirmation. Mock NFC is not a device.
- **QR camera.** `AVCaptureMetadataOutput` on a physical camera.
- **App Group container** (unsigned builds fall back to Application Support).
- **DeviceActivityMonitor firing** in the background, including overnight 22:00-07:00. The Monitor extension target exists; schedule auto-start on a phone is unverified.
- **Emergency unblock** while a real shield is on. Simulator count fallback is UserDefaults, not Keychain.
- **Felica.** The reader polls ISO14443 and ISO15693 only. Japanese FeliCa cards are not in the polling set.

## Audit (stubs / leftovers)

Searched for `would go here`, `asyncAfter`, `TODO`, `FIXME`, `fatalError`, and `demo-` outside `#if DEBUG`.

**True now**
- Key setup scans through the real NFC scanner. Cards need two matching taps. Tags register UID and try to write an Open Blocker NDEF record; UID still works if write fails.
- Block tab uses `KeyScanner` (NFC, QR, or chooser). Simulator QR is paste; device QR is camera.
- Rules "How to set a Screen Time passcode" opens Apple's Screen Time guide.
- `AppState` posts `sessionStarted` so the anonymous Count feature can see a block.
- Demo Desk Key matches `MockNFCScanner.defaultUID`.
- Emergency count write is verified; UserDefaults fallback when Keychain is unavailable.
- Demo history includes a finished 32-minute session today.
- `SessionManager.swift` and unused `AuthorizationManager.swift` were deleted.

**Still true, not fake**
- Simulator `ScheduleMonitor.sync` does not call `DeviceActivityCenter`. Local notifications for schedule end are scheduled in the app process when a scheduled session is active.
- UITest pauses use `asyncAfter` for holds; that is test timing, not product logic.
- Demo secrets for Keychain Card (`demo-card-456`) and Gym QR (`demo-qr-789`) live in `DemoData.swift` under `#if DEBUG`. Desk Key uses the mock NFC UID.
- Home key art loads `KeyModel.usdz` in SceneKit when the file is in the bundle, and falls back to a 2D `KeyArt` shape if it is missing.
- Outfit font is not bundled.
