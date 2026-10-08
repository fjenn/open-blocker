# Privacy Policy

**Effective Date:** October 8, 2026

Open Blocker is designed with privacy as a core principle. This document explains what data the app collects and how it is used.

## Data Collection

### Local Data Only (Default)

By default, Open Blocker stores all data locally on your device and never sends anything over the internet:

- **Blocked app list**: Stored on your device
- **NFC tag pairings and QR key payloads**: Stored on your device
- **Blocking session state**: Stored on your device
- **App settings**: Stored on your device

This local data is never transmitted anywhere.

### Optional Anonymous Count

Open Blocker includes an opt-in "Count me" toggle on the home screen, **OFF by default**.

If you enable this toggle, the app will:

1. Generate a random UUID (install ID) when you opt in
2. Send **one** HTTPS POST request:
   - **iPhone:** When the first focus session starts (when you scan your key)
   - **Android:** When the app successfully blocks an app for you (when the block screen actually appears)
3. Stop sending once one message has been sent

**What gets sent:**
- Random install ID (UUID, not linked to you)
- Event name: `first_block`
- App version (e.g., "0.1.0-alpha")
- Timestamp (added by the server)

**Why the difference:** The iPhone app uses Apple's Screen Time API, which doesn't allow detecting when shields are shown. The ping fires when you start a session. The Android app detects blocked app launches directly, so the ping fires when the block screen appears.

**What is NOT sent:**
- Device information
- iOS or Android version
- Phone model
- Which apps you block
- When you use the app
- Your location
- We don't store IP addresses in our table; Supabase may keep standard server logs

**Why we collect this:**

The anonymous count helps us understand how many people use Open Blocker successfully. One ping per install tells us the project is helping people focus, which motivates continued development and helps us prioritize improvements.

**Server:**

The ping is sent to a Supabase database with Row Level Security enabled. Anonymous users can only insert, never read. The data is aggregated periodically to count unique installs by day and version.

### Optional Review Prompt (iPhone Only)

After your 3rd session start, the iPhone app may ask you for a short review. This is optional. If you send one, we receive:

- Review text
- Install ID (the same random UUID from the count feature)
- App version (e.g., "1.0.0")
- Platform ("ios")
- Email address (only if you type one; optional)
- Server timestamp (added by the server)

The Android app does not have review prompts.

If you provide an email address, we use it only to follow up on your review. You can request deletion at any time.

## Permissions

Open Blocker requests these Android permissions:

- **NFC**: Required to read and write NFC tags and cards
- **Camera**: Requested only when you scan a QR key. Frames are decoded on-device with ZXing and are not stored or sent. You can deny the permission and still use NFC keys.
- **Accessibility**: Required to detect when blocked apps open during a blocking session
- **Query All Packages**: Required to show you a list of installed apps to choose which to block
- **Internet**: Declared in the app manifest unconditionally. When `COUNT_ENABLED` is false at build time, the network code is switched off and never runs. When enabled, used only for the optional anonymous count feature described above

## No Third-Party Tracking

Open Blocker contains:
- No analytics SDKs
- No crash reporting services
- No advertising frameworks
- No user tracking of any kind

## Your Rights

- You can disable the "Count me" toggle at any time in the app
- The app will immediately stop attempting to send data
- All data remains on your device and you can uninstall the app at any time to remove it

## Open Source

Open Blocker is open source (MIT license). You can review the complete source code to verify these privacy claims:

The source is this repository.

## Changes

If we make changes to this privacy policy, we will update the Effective Date at the top and note the changes in the app's release notes.

## Contact

For privacy questions, open a GitHub issue or email the address below.

**Privacy contact:** finn.jennen@gmail.com
