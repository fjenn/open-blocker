# Manual Testing Guide

**0.1.0-alpha is an early alpha, not tested on real devices.** NFC and QR keys have been tried on an Android emulator only. This document is a phone test script, not a claim that the app is ready for daily use. Please report results in GitHub Issues or Discussions.

This guide walks you through testing Open Blocker on a real Android device. It should take about 1 hour.

For a shorter 15-minute phone pass, use [android/DEVICE-TEST.md](../android/DEVICE-TEST.md).

## Which APK to Use

Open Blocker has two build variants:

- **`app-release.apk`** (normal): Use for all sections EXCEPT Section 4
- **`app-release-test.apk`** (test mode): Use ONLY for Section 4

The test APK includes a "Quick Test" button that allows starting/stopping sessions without the physical key. This is a security hole in production use, so it only exists in test builds. Section 4 tests this button, then you should uninstall the test APK and reinstall the normal APK for the rest of testing.

**Important:** Sections 5-9 verify that the normal APK properly requires the physical key. If you skip these sections, you won't verify that the hole doesn't exist in the production build.

## What You Need

- Android phone (Android 7.0 or newer). NFC is required for tag/card tests; a camera is required for QR tests
- One NFC tag (NTAG213, NTAG215, or NTAG216) OR any NFC card (transit card, hotel key, work badge), and/or a printed Open Blocker QR
- Both APKs: `app-release.apk` and `app-release-test.apk`
- About 1 hour of time

## Before You Start

- Make sure NFC is turned on in your phone settings
- Have the APK installed (see README for installation instructions)
- Have your NFC tag or card ready

## How to Use This Checklist

For each step:
1. Read the **Action** (what to do)
2. Perform the action on your phone
3. Check the **Expected Result** (what should happen)
4. Mark **Pass** if it worked, **Fail** if it did not, or write a note

If something fails, continue with the rest of the test and note what went wrong.

---

## Test Steps

### Section 1: Initial Setup and Permissions

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 1.1 | Open the Open Blocker app for the first time | App launches and shows the home screen with "Not Blocking" message | |
| 1.2 | Look at the home screen | You see cards for "Blocked Apps", "NFC Tags", "Printed QR key", and "Accessibility Permission" | |
| 1.3 | Scroll down to the "⚠ Honesty Note" card | Card says "A determined user can get around the block on Android... Open Blocker adds friction, not a lock" | |
| 1.4 | Tap "Open Accessibility Settings" | Android Settings opens to the Accessibility screen | |
| 1.5 | Find and tap "Open Blocker" in the list | A warning screen appears saying accessibility services can read screen content | |
| 1.6 | Tap "Allow" or "OK" to enable the service | Toggle turns on, and you see "Open Blocker - On" | |
| 1.7 | Press the back button to return to Open Blocker | Home screen now shows "✓ Accessibility service is enabled" in green | |

**If Step 1.5-1.7 show a "Restricted Settings" warning on Android 13+:**
- You will need to allow restricted settings first
- Tap "Open App Settings" on the warning card
- Tap "Allow restricted settings"
- Then return to Step 1.4

---

### Section 2: Select Apps to Block

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 2.1 | On the home screen, tap "Manage Blocked Apps" | A new screen appears showing a list of installed apps | |
| 2.2 | Scroll through the list | You see app names with icons and checkboxes | |
| 2.3 | Tap the checkbox next to Chrome (or any browser) | The checkbox fills in | |
| 2.4 | Tap the checkbox next to Calculator | The checkbox fills in | |
| 2.5 | Tap the checkbox next to Clock or Calendar | The checkbox fills in | |
| 2.6 | Count how many apps you selected | You have 3 apps selected | |
| 2.7 | Tap the back arrow at the top left | You return to the home screen | |
| 2.8 | Look at the "Blocked Apps" card | It now says "3 apps blocked" (or the number you selected) | |

---

### Section 3A: Pair an NFC Tag (Write Open Blocker Format)

**Do this section if you have a blank NTAG213/215/216 tag that you want to write.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 3A.1 | On the home screen, tap "Pair NFC Tag" | A new screen appears with two pairing options | |
| 3A.2 | Tap the blue "Write Tag" button | A blue card appears saying "Ready to write tag" with a phone emoji | |
| 3A.3 | Hold your blank NFC tag against the back of your phone | Your phone vibrates or beeps (NFC detected) | |
| 3A.4 | Keep holding the tag for 1-2 seconds | A toast message pops up saying "Tag written and paired successfully" | |
| 3A.5 | Lower the tag away from your phone | The pairing screen disappears and you return to tag pairing screen | |
| 3A.6 | Tap the back arrow to return to home | You are back at the home screen | |

**If Step 3A.4 fails:**
- Try different positions on the back of your phone
- Make sure NFC is enabled in phone settings
- Make sure the tag is not already locked or read-only
- Skip to Section 3B and try "Pair by UID" instead

**After completing Section 3A, skip to Section 4.**

---

### Section 3B: Pair an NFC Tag or Card (Without Writing)

**Do this section if you want to use an existing tag, card, or if Section 3A failed.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 3B.1 | On the home screen, tap "Pair NFC Tag" | A new screen appears with two pairing options | |
| 3B.2 | Tap the "Pair by UID" button (outlined, not filled) | A blue card appears saying "Ready to pair tag by UID" | |
| 3B.3 | Hold your NFC tag or card against the back of your phone | Your phone vibrates or beeps | |
| 3B.4 | Keep holding for 1-2 seconds | A toast message says "Tag paired by UID successfully" | |
| 3B.5 | Lower the tag away | You return to the pairing screen | |
| 3B.6 | Tap the back arrow to return home | You are back at the home screen | |

**If you want to use a transit card, hotel key, or work badge instead, try Section 3C below.**

---

### Section 3C: Pair Any NFC Card (Transit, Hotel, Work Badge)

**Do this section if you want to use a card you already own (Oyster, Clipper, SUBE, hotel key, work badge, etc.).**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 3C.1 | On the home screen, tap "Pair NFC Tag" | Pairing screen appears | |
| 3C.2 | Tap "Pair Any Card (Transit, Hotel, Badge)" | A new screen appears with instructions and warnings | |
| 3C.3 | Read the warnings about cards | Copy includes "Not every card works. Test yours." | |
| 3C.4 | Tap the blue "Start Pairing" button | A blue card appears saying "Tap 1 of 2" | |
| 3C.5 | Hold your card against the back of your phone | Phone vibrates or beeps | |
| 3C.6 | Keep holding for 1 second | A toast says "First scan successful. Tap the same card again." | |
| 3C.7 | Wait for the screen to update | The card now says "Tap 2 of 2" with a checkmark | |
| 3C.8 | Hold the SAME card against your phone again | Phone vibrates or beeps | |
| 3C.9 | Keep holding for 1 second | A toast says "Card paired successfully!" | |
| 3C.10 | The screen updates | A success card appears saying "Card Paired!" | |
| 3C.11 | Tap the blue "Done" button | You return to the pairing screen | |
| 3C.12 | Tap the back arrow to return home | You are back at the home screen | |

**If Step 3C.9 shows "Card IDs don't match":**
- Your card shows a new ID on each tap (random ID)
- Not every card works. Test yours.
- Try a different card or go back to Section 3B

---

### Section 3D: Printed QR key

**Do this section if you want a key with no NFC hardware. Needs a real camera and a printed (or on-screen) QR. Not emulator-proven for start/end/wrong-QR.**

The payload must be `openblocker://tag/v1/` plus 32 lowercase hex characters. A QR generated on iPhone is valid on Android.

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 3D.1 | On the home screen, tap "Add QR key" | Printed QR key screen | |
| 3D.2 | Tap "Generate QR Code" | A QR image appears and the key is saved | |
| 3D.3 | Tap "Share or print" and print or save the image | You have a physical QR | |
| 3D.4 | (Optional) Scan with camera and register a QR printed from iPhone | Camera permission once; then the scanner; key saved. Deny: Settings / Cancel | |
| 3D.5 | On home, tap "Scan QR to start or stop" and scan the paired QR | Toast "Blocking session started"; home shows "Blocking Active" | |
| 3D.6 | Open a blocked app | Block overlay. Tap "Scan QR key" on the overlay and scan the same QR | Overlay closes; session ended |
| 3D.7 | Start a session again, then scan a different QR (not the paired key) | Toast "Wrong key..." or "This QR is not an Open Blocker key."; session stays active | |

---

### Section 4: Test the Quick Start Button (TEST APK ONLY)

**⚠ INSTALL `app-release-test.apk` FOR THIS SECTION ONLY**

Before starting this section:
1. Uninstall the normal Open Blocker APK if installed
2. Install `app-release-test.apk`
3. Complete Section 1 (permissions) and Section 2 (select apps) again with the test APK

**This section tests the in-app button for starting a session without tapping your key. This feature only exists in test builds.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 4.0 | Look at the top of the home screen | You see a red "⚠ TEST BUILD" banner warning that this build includes test features | |
| 4.1 | Scroll down and look for the "Quick Test" card | You should see a "Quick Test" card with a button | |
| 4.2 | Read the button label | It says "Start Session (Test)" | |
| 4.3 | Tap the "Start Session (Test)" button | The button turns red and changes to "Stop Session (Test)" | |
| 4.4 | Look at the top card | It now shows "🔒 Blocking Active" in a colored box | |
| 4.5 | Press your phone's home button | You see your home screen or launcher | |
| 4.6 | Open one of the apps you blocked (e.g., Chrome) | Within 1-2 seconds, a full-screen red block screen appears | |
| 4.7 | Read the block screen message | It says "App Blocked" or similar, with a message about the app being blocked during this session | |
| 4.8 | Look for a "Go Back" button | There is a button at the bottom | |
| 4.9 | Tap "Go Back" | You return to your launcher or previous screen | |
| 4.10 | Open the same blocked app again | The block screen appears again (blocking is still active) | |
| 4.11 | Open Open Blocker again | You see the home screen still showing "🔒 Blocking Active" | |
| 4.12 | Scroll to the "Quick Test" card and tap "Stop Session (Test)" | The button turns blue and changes back to "Start Session (Test)" | |
| 4.13 | Look at the top card | It now shows "⏸️ Not Blocking" | |
| 4.14 | Press home and open the same blocked app again | The app opens normally without any block screen | |

**If the block screen does not appear in Step 4.6:**
- Go back to Section 1 and make sure accessibility is enabled
- Restart the Open Blocker app and try again
- Make sure you selected at least one app to block in Section 2

---

### Section 4B: Switch to Normal APK

**⚠ UNINSTALL TEST APK AND INSTALL NORMAL APK**

After completing Section 4, you must switch back to the normal APK for the rest of testing. The remaining sections verify that the production build properly requires the physical key.

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 4B.1 | Go to Android Settings > Apps > Open Blocker | You see the app info screen | |
| 4B.2 | Tap "Uninstall" | A confirmation dialog appears | |
| 4B.3 | Confirm uninstall | The test APK is removed | |
| 4B.4 | Install `app-release.apk` (normal build) | The app installs successfully | |
| 4B.5 | Open Open Blocker | The app launches | |
| 4B.6 | Look at the top of the home screen | There is NO red "TEST BUILD" banner (it's the normal build) | |
| 4B.7 | Complete Section 1 (permissions) and Section 2 (select apps) again | Accessibility is enabled and apps are selected | |
| 4B.8 | Look for the "Quick Test" card | The "Quick Test" card does NOT exist in the normal build | |

**If you see the "Quick Test" card in Step 4B.8, you installed the wrong APK. Repeat Section 4B with the correct `app-release.apk` file.**

---

### Section 5: Test Blocking with Your Physical Key

**This section tests starting and stopping with your NFC tag or card. Uses NORMAL APK. For a printed QR key, use Section 3D.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 5.1 | Make sure the home screen shows "⏸️ Not Blocking" | If blocking is active from a previous section, it should have been cleared when you reinstalled | |
| 5.2 | Hold your paired tag or card against the back of your phone | Phone vibrates or beeps | |
| 5.3 | Keep holding for 1 second | A toast says "Blocking session started" | |
| 5.4 | Lower the tag away | The home screen updates to "🔒 Blocking Active" | |
| 5.5 | Press home and open a blocked app | The block screen appears within 1-2 seconds | |
| 5.6 | Return to Open Blocker (without tapping "Go Back") | Home screen still shows "🔒 Blocking Active" | |
| 5.6b | Look for the "Quick Test" card or any button to stop without the key | No such button exists (this is the normal build) | |
| 5.6c | Try pressing home and reopening Open Blocker several times | Blocking remains active - there is NO WAY to stop it without the key | |
| 5.7 | Hold the SAME tag or card against your phone again | Phone vibrates or beeps | |
| 5.8 | Keep holding for 1 second | A toast says "Blocking session ended" | |
| 5.9 | Lower the tag away | The home screen updates to "⏸️ Not Blocking" | |
| 5.10 | Press home and open a previously blocked app | The app opens normally (no block screen) | |

---

### Section 6: Test Debug Screen

**This section checks that the app is logging NFC scans correctly.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 6.1 | On the home screen, scroll to the bottom | You see a text button "Debug Info (for testing)" | |
| 6.2 | Tap "Debug Info (for testing)" | A debug screen appears with technical information | |
| 6.3 | Look at the "Last Scanned Tag" section | You see the UID (hardware ID) of the last tag you scanned | |
| 6.4 | Look at the "Paired Tags" section | You see a list of tag IDs you have paired | |
| 6.5 | Look at the "Paired UIDs" section | You see a list of hardware UIDs you have paired | |
| 6.6 | Tap the back arrow | You return to the home screen | |

---

### Section 7: Test Count Me Feature (if enabled)

**If you do not see a "Count me" card on the home screen, this feature was disabled at build time. Skip this section.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 7.1 | Look for a "Count me" card on the home screen | If present, you see a toggle switch that is OFF by default | |
| 7.2 | Read the description text | It says "Send one anonymous ping after your first successful block (helps us understand reach)" | |
| 7.3 | Tap the toggle switch to turn it ON | The switch moves to the ON position | |
| 7.4 | Start a blocking session and open a blocked app | The block screen appears as usual | |
| 7.5 | Return to the home screen | No visible change (the ping happens in the background) | |
| 7.6 | Close and reopen the app | The "Count me" toggle is still ON (your preference was saved) | |

**Note:** The anonymous ping is sent once after the first successful block. You will not see any confirmation, as it happens silently in the background.

---

### Section 8: Test Accessibility Across Restarts

**This section checks that blocking persists correctly.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 8.1 | On the home screen, start a blocking session (use your key or the test button) | Home screen shows "🔒 Blocking Active" | |
| 8.2 | Force-close the Open Blocker app (swipe it away from recent apps) | App closes | |
| 8.3 | Open a blocked app | The block screen still appears (blocking is still active) | |
| 8.4 | Restart your phone (full reboot) | Phone restarts | |
| 8.5 | After reboot, open Open Blocker | Home screen shows "⏸️ Not Blocking" (session was cleared by reboot) | |
| 8.6 | Open a previously blocked app | The app opens normally (blocking is not active) | |

**Expected behavior:** Blocking sessions do NOT survive a phone reboot. This is by design.

---

### Section 9: Verify Honesty Note and Bypass Information

**This section confirms that the app is honest about its limitations.**

| Step | Action | Expected Result | Pass/Fail/Notes |
|------|--------|----------------|-----------------|
| 9.1 | On the home screen, scroll to the "⚠ Honesty Note" card | You see a card with a warning icon | |
| 9.2 | Read the full text | It says "A determined user can get around the block on Android (for example via safe mode, uninstalling the app, turning off the Accessibility service, or ADB). Open Blocker adds friction, not a lock." | |
| 9.3 | Start a blocking session | Blocking is active | |
| 9.4 | Go to Android Settings > Apps > Open Blocker > Force Stop | Open Blocker stops | |
| 9.5 | Open a blocked app | The app opens normally (blocking stopped when the app was force-stopped) | |

**Expected behavior:** The app is bypassable by design. It is not a security lock.

---

## Summary Checklist

After completing all sections, answer these questions:

| Question | Yes/No/Notes |
|----------|--------------|
| Did the app install and launch without errors? | |
| Were you able to enable accessibility permission? | |
| Were you able to select apps to block? | |
| Were you able to pair an NFC tag or card? | |
| Did the in-app "Start Session" button work? | |
| Did the block screen appear when you opened a blocked app? | |
| Did tapping your physical key start and stop blocking? | |
| Did the debug screen show correct information? | |
| Was the "Honesty Note" visible and clear? | |
| Did blocking stop after a phone reboot (expected)? | |

---

## Test Results

**Date:** _______________  
**Device Model:** _______________  
**Android Version:** _______________  
**App Version:** _______________  
**Overall Result:** PASS / FAIL  

**Issues Found:**

(Write any problems you encountered here)

---

## Known Limitations (Not Bugs)

These behaviors are expected:

- Block screen takes 1-2 seconds to appear (Android accessibility delay)
- Blocking does not survive a phone reboot (by design)
- Block can be bypassed by turning off accessibility, uninstalling, safe mode, or ADB (by design)
- Some system apps may not be blockable (Android restriction)
- Not every card works. Test yours.

---

## What to Do If Something Failed

- **NFC not detected:** Make sure NFC is on, try different positions, confirm tag is compatible
- **Block screen not appearing:** Restart app, check accessibility is enabled, verify Android version
- **Tag pairing failed:** Try "Pair by UID" instead of "Write Tag"
- **Any-card rejected:** Card may have random ID (try a different card)
- **App crashes:** Note the step, check device logs, report the issue on GitHub

---

## Next Steps

If all tests passed:
- Use Open Blocker daily and note any issues
- Report bugs or feedback on GitHub
- Share your experience with others

If tests failed:
- Note which steps failed
- Report the issue on GitHub with your device model and Android version
- Try again after updates

---

**End of Testing Guide**
