# TestFlight Setup Guide

This guide walks you through preparing Open Blocker for TestFlight distribution on the iOS App Store.

## Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode 15.0 or later
- macOS with Xcode installed
- App built and tested locally

## Step 1: App Store Connect Setup

### Create App Record

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** and click the **+** button
3. Select **New App**
4. Fill in the details:
   - **Platform**: iOS
   - **Name**: Open Blocker
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `org.openblocker.OpenBlocker` (must match Xcode project)
   - **SKU**: `openblocker-ios` (any unique identifier)
   - **User Access**: Full Access

### App Information

1. Go to your app in App Store Connect
2. Under **App Information**, fill in:
   - **Privacy Policy URL**: https://openblocker.vercel.app/privacy
   - **Category**: Productivity (Primary), Health & Fitness (Secondary)
   - **Content Rights**: Check if you own or have licensed rights

### Age Rating

1. Go to **App Information** > **Age Rating**
2. Answer the questionnaire (should result in 4+ rating)

## Step 2: Beta App Review Information

TestFlight requires Beta App Review before external testing. Include these notes:

### What to Test

```
Open Blocker is a physical phone blocker that uses NFC tags, NFC cards, or QR codes as keys to start and stop app blocking sessions.

To test the core functionality:

1. Launch the app and grant Family Controls authorization when prompted
2. On the home screen, tap "Select Apps to Block"
3. Choose one or more apps (e.g., Safari, Mail, Messages)
4. Tap "Done" to save your selection
5. Return to the home screen

For testing without an NFC tag:

6. Tap "Manage Keys" on the home screen
7. Tap "Generate QR Key"
8. A QR code will be displayed (this is your test key)
9. Return to the home screen and tap "Scan Key"
10. Tap "Scan QR Code" and scan the QR code you just generated
11. The app will start a blocking session
12. Press the home button and try to open one of the blocked apps
13. You should see the iOS Screen Time shield preventing access
14. Return to Open Blocker, tap "Scan Key" again, and scan the same QR code
15. The blocking session will end, and apps will be accessible again

The app uses Apple's Family Controls framework to apply and remove app shields. No network access is required for core functionality.
```

### Beta App Review Notes

```
Reviewer Demo Key:

For your convenience, here is a QR code URL you can use to test the app without writing an NFC tag:

openblocker://tag/v1/a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

To use this key:
1. Open the app
2. Tap "Manage Keys"
3. Tap "Pair Existing Key"
4. Tap "Scan QR Code"
5. When the camera opens, manually enter the URL above in Safari
6. Copy the URL and paste it into the app's manual entry field (tap "Enter Manually" if available)
   OR screenshot this URL as a QR code and scan it

Alternatively, you can generate a new QR key directly in the app:
1. Tap "Manage Keys"
2. Tap "Generate QR Key"
3. Use this generated QR code to start/stop blocking

Family Controls Justification:

Open Blocker uses the Family Controls framework (FamilyControls.framework and ManagedSettings.framework) to apply app and category shields during blocking sessions. The app:

- Requests individual authorization (not parent/guardian)
- Uses FamilyActivityPicker for user-controlled app selection
- Applies shields via ManagedSettingsStore only when the user scans their physical key
- Clears shields when the user scans the same key again

The app does not collect, store, or transmit any user activity data. All settings are stored locally on the device.

Export Compliance:

This app does not use encryption beyond what is provided by the operating system and does not require an export compliance review. The app declares ITSAppUsesNonExemptEncryption = NO in its Info.plist.

Testing Notes:

- The app requires iOS 16.0 or later
- Family Controls authorization is required for blocking to work
- Camera permission is needed for QR code scanning (optional feature)
- NFC reading is optional and requires iPhone 7 or later with NFC capability

Thank you for reviewing Open Blocker.
```

## Step 3: Build for TestFlight

### In Xcode

1. Open `ios/OpenBlocker.xcodeproj` in Xcode
2. Select the **OpenBlocker** target
3. Select **Any iOS Device** as the destination
4. Go to **Product** > **Archive**
5. Wait for the archive to complete
6. The Organizer window will open automatically

### Upload to App Store Connect

1. In the Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Click **Upload**
5. Ensure **Include bitcode** is unchecked (not supported in Xcode 14+)
6. Ensure **Upload your app's symbols** is checked (recommended for crash reports)
7. Click **Upload**

The build will be processed by Apple (takes 5-30 minutes).

## Step 4: TestFlight Configuration

### Internal Testing (Optional)

1. In App Store Connect, go to **TestFlight** > **Internal Testing**
2. Click the **+** button to create a new group
3. Add internal testers (up to 100, must have App Store Connect access)
4. Select the build you uploaded
5. Internal testing can begin immediately (no review required)

### External Testing (Public Link)

1. In App Store Connect, go to **TestFlight** > **External Testing**
2. Click the **+** button to create a new group
3. Name it (e.g., "Open Blocker Public Beta")
4. Enable **Public Link**
5. Add the build you uploaded
6. Fill in **Test Information**:
   - **What to Test**: (Use the text from Step 2 above)
   - **Beta App Description**: "Open Blocker is an open source physical phone blocker. Tap an NFC tag, card, or QR code to start blocking distracting apps. Tap again to stop."
   - **Feedback Email**: Your support email
   - **Marketing URL**: https://openblocker.vercel.app/
   - **Privacy Policy URL**: https://openblocker.vercel.app/privacy
7. Click **Submit for Review**

Beta App Review typically takes 24-48 hours.

### After Approval

1. Once approved, go to **External Testing** > your group
2. Click **Public Link** to get the shareable TestFlight link
3. Share this link (e.g., `https://testflight.apple.com/join/XXXXXXXX`)

Anyone with the link can install the app (up to 10,000 testers).

## Step 5: TestFlight Installation (For Testers)

### Install TestFlight App

1. Download **TestFlight** from the App Store (free, by Apple)

### Join the Beta

1. Open the public TestFlight link on your iPhone
2. Tap **View in TestFlight** or **Start Testing**
3. Tap **Accept** to agree to testing terms
4. Tap **Install**

The app will install like a regular App Store app.

### Testing Feedback

Testers can send feedback directly from TestFlight:

1. Open TestFlight
2. Select Open Blocker
3. Tap **Send Beta Feedback**
4. Attach screenshots, describe issues, etc.

Feedback goes to the email you specified in App Store Connect.

## Export Compliance

Open Blocker declares `ITSAppUsesNonExemptEncryption = NO` in its Info.plist. This means:

- The app does not use encryption beyond what iOS provides
- No export compliance documentation is required
- No additional review steps for encryption

If App Store Connect asks about export compliance during upload:

1. Select **No** when asked "Is your app designed to use cryptography or does it contain or incorporate cryptography?"
2. Continue with the upload

This is already configured in the Xcode project.

## Troubleshooting

### Build Processing Stuck

If the build has been "Processing" for over 1 hour:

1. Check your email for rejection notices from Apple
2. Common issues:
   - Missing entitlements
   - Invalid provisioning profile
   - Export compliance mismatch

### TestFlight Build Not Appearing

After upload:

1. Wait 5-30 minutes for processing
2. Check **Activity** tab in App Store Connect for errors
3. Ensure you selected the correct bundle ID when creating the app record

### Family Controls Not Working in TestFlight

Family Controls requires:

1. iOS 16.0 or later
2. Individual authorization (requestAuthorization called)
3. Proper entitlements in the app
4. User must grant permission when prompted

If shields do not appear:

1. Check that Family Controls authorization was granted (Settings > Screen Time > [App Name])
2. Verify the app is not in a restricted Screen Time mode itself

### Beta App Review Rejection

Common reasons:

- Unclear testing instructions
- Missing demo account/content
- Crashes on launch

If rejected:

1. Read the rejection email carefully
2. Update the **What to Test** section with clearer instructions
3. Add the demo key URL from this guide
4. Resubmit the same build (no need to upload again)

## Resources

- [App Store Connect Guide](https://developer.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Beta App Review Guidelines](https://developer.apple.com/testflight/beta-review-guidelines/)
- [Export Compliance](https://developer.apple.com/documentation/security/complying_with_encryption_export_regulations)

## Next Steps After TestFlight

Once testing is complete and you are ready for public release:

1. Create App Store screenshots (required: 6.5" and 5.5" iPhone)
2. Write an App Store description (max 4,000 characters)
3. Submit for App Review (not Beta Review)
4. Wait 1-7 days for review
5. Release to the App Store

See `docs/APPLE.md` for App Store submission guidelines.
