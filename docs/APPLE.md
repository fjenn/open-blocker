# Apple App Store Documentation

This document contains information needed for Apple review and distribution.

## Bundle IDs

**Main App:**
- `org.openblocker.OpenBlocker`

**Note:** The ShieldConfiguration extension is NOT needed. iOS provides a default system shield when using `ManagedSettingsStore.shield`, which displays a black screen with "This app is currently blocked" message. The default shield is sufficient for v1.

## Capabilities and Entitlements

### Family Controls
**Entitlement:** `com.apple.developer.family-controls`

**Usage Description:**
Open Blocker uses Family Controls to help users block distracting apps during focus sessions. When a user starts a blocking session by scanning their physical key (QR code or NFC tag), the app applies shields to selected apps and categories using ManagedSettingsStore. The shields persist until the user ends the session by scanning their key again. This creates a physical barrier to app distractions. The app does not monitor usage, share data with third parties, or control other people's devices. It is designed for individual use only, with explicit user-initiated session control.

### NFC Tag Reading
**Entitlement:** `com.apple.developer.nfc.readersession.formats`  
**Formats:** NDEF, TAG

**Usage:** Users can register NFC tags and cards as physical keys to start and stop blocking sessions. The app reads both NDEF messages (for Open Blocker format tags written by the app) and raw tag identifiers (for any-card registration of transit cards, hotel keys, work badges).

### Camera (for QR scanning)
**Info.plist Key:** `NSCameraUsageDescription`  
**Value:** "Open Blocker uses the camera to scan QR codes as your physical key for blocking sessions."

## App Store Privacy Labels

### Data Collected

**Optional Anonymous Usage Data:**
- **Type:** Product Interaction (first block event only)
- **Linked to User:** No
- **Used for Tracking:** No
- **Purpose:** Analytics only
- **Details:** If the "Count me" toggle is on (on by default, can be turned off anytime in Settings), one anonymous ping is sent after the first successful block. Contains only: random install ID (UUID), event name "first_block", and app version. Nothing is sent unless the count server is configured at build time.

**Optional Reviews (after 3rd block):**
- **Type:** User Content (review text)
- **Type:** Contact Info (email, optional)
- **Linked to User:** No (unless email provided)
- **Used for Tracking:** No
- **Purpose:** App Functionality and Product Improvement
- **Details:** User may optionally submit a one-line review after their 3rd block. Email is optional and used only to follow up on feedback. User can request deletion.

### Data Not Collected

- Device ID, IDFA, or hardware identifiers
- Precise location
- Usage data (which apps blocked, session duration)
- Diagnostics
- Browsing history
- Search history
- Photos or files

### Third-Party Data Sharing

None. All network requests go to our own Supabase backend (documented in PRIVACY.md). No third-party SDKs, analytics, or tracking.

## Setup Instructions

### Prerequisites
1. macOS with Xcode 15.0 or later
2. Apple Developer account

### First-Time Setup

1. **Install XcodeGen:**
   ```bash
   brew install xcodegen
   ```

2. **Clone and Generate Project:**
   ```bash
   cd ios
   xcodegen generate
   ```
   This creates `OpenBlocker.xcodeproj` from `project.yml`.

3. **Open in Xcode:**
   ```bash
   open OpenBlocker.xcodeproj
   ```

4. **Configure Signing (Development):**
   - Select `OpenBlocker` target
   - Go to Signing & Capabilities
   - Check "Automatically manage signing"
   - Select your development team
   - Xcode will create a development provisioning profile

5. **Add Family Controls Capability:**
   - In Signing & Capabilities tab
   - Click "+ Capability"
   - Add "Family Controls"
   - This adds the entitlement to your development profile
   
   **Note:** For development, the Family Controls capability works immediately. For App Store distribution, you need to request the distribution entitlement from Apple:
   - Go to https://developer.apple.com/contact/request/family-controls-distribution
   - Submit the usage description above
   - Apple reviews and approves (usually 2-4 weeks)

6. **Configure Count Feature (Optional):**
   
   If you want to enable anonymous counting:
   
   - Create or edit `ios/Config/Debug.xcconfig`:
     ```
     COUNT_URL = https://your-supabase-project.supabase.co
     COUNT_KEY = your_anon_key
     ```
   
   - Create or edit `ios/Config/Release.xcconfig` with production values
   
   If you leave these empty, the "Count me" toggle will be hidden and no network code runs. The toggle is on by default when the feature is enabled at build time.

7. **Build and Run:**
   - Select your iPhone from the device dropdown
   - Click Run (Cmd+R)
   - First launch will prompt to trust the developer certificate on your iPhone (Settings > General > VPN & Device Management)

### Known Build Issues

**Family Controls Simulator Limitation:**
- Family Controls APIs do not work in Simulator
- You MUST test on a real iPhone
- Build will succeed in Simulator but authorization will fail at runtime

**NFC Simulator Limitation:**
- NFC APIs are not available in Simulator
- QR code scanning works in Simulator via simulated camera

### Release Build

1. **Set up Release Signing:**
   - Create App ID in Apple Developer portal: `org.openblocker.OpenBlocker`
   - Create Distribution certificate and provisioning profile
   - In Xcode, set CODE_SIGN_IDENTITY and PROVISIONING_PROFILE_SPECIFIER in Release config

2. **Archive:**
   - Product > Archive
   - Upload to App Store Connect

3. **App Store Connect Setup:**
   - Create app entry
   - Upload screenshots (iPhone 6.7" and 6.5" required)
   - Fill privacy labels (see above)
   - Set category: Productivity
   - Set age rating: 4+ (no restricted content)
   - Submit for review

## Distribution Entitlement Request

When ready for App Store release:

1. Go to https://developer.apple.com/contact/request/family-controls-distribution
2. Provide:
   - Bundle ID: `org.openblocker.OpenBlocker`
   - App Name: Open Blocker
   - Usage description (from above)
   - Confirmation that app is for individual use only
3. Wait for Apple's approval (check email)
4. Once approved, you can submit to App Store

## Version Numbers

- **CFBundleShortVersionString:** 1.0.0 (user-facing version)
- **CFBundleVersion:** 1 (build number, increment for each App Store submission)

Update these in `project.yml` under the `info` section before release.

## Website and Privacy Policy

**Website:** https://openblocker.vercel.app/  
**Privacy Policy:** https://openblocker.vercel.app/privacy

Use these URLs in:
- App Store Connect app information (Privacy Policy URL field)
- TestFlight Beta App Review information
- App Store screenshots and marketing materials
