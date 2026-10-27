# Privacy Policy

**Effective Date:** October 27, 2026

Open Blocker is designed with privacy as a core principle. This document explains what data the apps collect and how it is used. It matches the code in this repository. The iPhone and Android apps do not behave the same way, so each platform is described separately.

## Data stored only on your device

Both apps store this on the device and do not send it:

- Blocked app list and modes
- NFC tag pairings and QR key payloads
- Blocking session state and local history
- App settings, including the anonymous count toggle

Uninstalling the app removes this local data.

## Anonymous count

Both apps have a Settings toggle labeled **Share anonymous count**. It is **on by default**. You can turn it off at any time.

Turning the toggle off stops further sends. Already-delivered events are not deleted from the server by the toggle.

### iPhone (1.0.0 on the App Store)

Source: `ios/OpenBlocker/Managers/CountManager.swift`, `ios/OpenBlocker/Managers/AppState.swift`, `ios/Config/Release.xcconfig`.

The shipped Release build has `COUNT_ENDPOINT` set to `https://openblocker.org/api/count`. The toggle defaults on (`CountManager.enabledByDefault = true`). On first launch the app creates a random install UUID if the toggle is on.

**When something is sent:** after a block is completed, and again on launch or when the app returns to the foreground if a send failed earlier. A completed block is one that ended by scanning your key, by a schedule end, or by a passage window. Emergency unblocks and lost Screen Time access are not sent. The first run after this feature exists marks any older history as already seen and does not send those older blocks.

**What each HTTPS POST contains (and nothing else):**

- `installId`: random UUID created on this phone
- `event`: `block_completed`
- `eventId`: the session's random UUID (so a retry is not counted twice)
- `appVersion`: the marketing version string (for 1.0.0, `"1.0.0"`)
- `platform`: `"ios"`

The client does not send app names, session times, device model, OS version, location, or an email.

**How many events:** one event per completed block while the toggle is on, not one ping per install. Distinct `installId` values count people who finished at least one block. Distinct `eventId` values count blocks.

**When nothing is sent:** the toggle is off, or `COUNT_ENDPOINT` is empty (then the network path never runs). Demo and simulator builds do not send unless `OB_SEND_COUNTS=1` is set.

### Android (0.2.0-alpha on GitHub Releases, and current source)

Source: `android/app/src/main/java/app/openblocker/android/data/CountManager.kt`, `SessionManager.kt`, `AppBlockingService.kt`, `android/app/build.gradle.kts`, `.github/workflows/build.yml`.

The Settings toggle also defaults on (`CountManager.enabledByDefault = true`). That is not enough to send data. Counting is compiled in only when `OPENBLOCKER_COUNT_URL` is set at build time (`BuildConfig.COUNT_ENABLED`). The GitHub Release workflow does not set that variable. The public `openblocker-0.2.0-alpha.apk` therefore has no count URL and **sends nothing**.

If you build current source with `OPENBLOCKER_COUNT_URL` set, the app will try to send **one** HTTPS POST the first time a blocking session starts (`SessionManager.startSession`) or the first time the block screen is shown (`AppBlockingService.fireBlock`), whichever happens first while counting is enabled. A failed send is retried the next time the app opens.

**What that POST contains (and nothing else):**

- `install_id`: random UUID
- `event`: `first_block`
- `app_version`: `BuildConfig.VERSION_NAME`
- `platform`: `"android"`

The install ID is created when the user turns the setting on (`setCountingEnabled(true)`). The default-on state does not create an ID by itself. If `COUNT_KEY` is set at build time, the request also sends `apikey` and `Authorization` headers for that endpoint. No app names, session times, device model, OS version, location, or email are in the body.

Android does not send a per-block event and does not send `eventId`.

## Reviews

The iPhone source has leftover review-send code (`CountManager.sendReview` and a `.showReviewPrompt` notification after the 3rd session start). No screen observes that notification or calls `sendReview`. `COUNT_URL` and `COUNT_KEY` are empty in `ios/Config/Release.xcconfig`, and `sendReview` returns immediately when they are empty. The shipped iPhone app does not collect reviews, install IDs for reviews, or email addresses.

The Android app has no review prompt and no review send path.

## Permissions

### iPhone

- **Screen Time (Family Controls):** required so the app can shield selected apps. The app does not read or upload your Screen Time usage report.
- **NFC:** reads and sets up your key tag or card. Tag IDs stay on the device.
- **Camera:** scans a QR or barcode key. Frames are not stored or sent.
- **Notifications:** optional. If you turn them on, the app can tell you when a block ends. Alerts stay on the device.

### Android

- **NFC:** reads and writes key tags and cards
- **Camera:** requested when you scan a QR key. Frames are decoded on-device with ZXing and are not stored or sent. You can deny the permission and still use NFC keys.
- **Accessibility:** required to detect blocked apps and, while a session is on, to read the address bar of supported browsers so website rules can be enforced. Those addresses are not stored or sent.
- **Notifications:** optional. If you allow them, the app can tell you when a block ends.
- **Vibrate:** haptic feedback
- **Internet:** declared in the manifest. Used only for the anonymous count described above, and only when counting is compiled in and the toggle is on
- **Launcher app query:** the manifest queries apps that have a launcher icon, so the app picker can list them. This is not the old `QUERY_ALL_PACKAGES` permission.

## No third-party tracking

Open Blocker contains:

- No analytics SDKs
- No crash reporting services
- No advertising frameworks
- No accounts

The iPhone count POST goes to `https://openblocker.org/api/count`. The client does not send your IP address. Any HTTPS server can see the connecting IP in ordinary request logs.

## Your rights

- Turn off **Share anonymous count** in Settings to stop further sends
- Uninstall the app to remove local data
- The apps do not offer an in-app delete of events already delivered

## Open source

Open Blocker is open source (MIT license). The source is this repository.

## Changes

If we make changes to this privacy policy, we will update the Effective Date at the top.

## Contact

For privacy questions, open a GitHub issue or email the address below.

**Privacy contact:** finn.jennen@gmail.com
