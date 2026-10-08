# Testing Open Blocker on iPhone

Simulator demo (`run-demo.command`) cannot prove shields, CoreNFC, or the camera. This checklist is for a physical iPhone.

None of these steps has been run on hardware yet. See `STATUS.md`.

## Prerequisites

- Mac with Xcode
- iPhone, iOS 16.0 or later (NFC needs iPhone 7 or later)
- Cable
- Optional hardware: NTAG213/215/216 sticker, a card with a stable chip ID (transit, hotel, work badge), a printed QR
- Your own Apple ID in Xcode for signing. This repo is not signed here.

## Install from Xcode

1. Connect the iPhone, unlock it, Trust the computer.
2. `cd ~/Projects/Coding/open-blocker/ios && xcodegen generate && open "Open Blocker.xcodeproj"`
3. Select the OpenBlocker target > Signing & Capabilities > Automatically manage signing > your Team.
4. Family Controls, App Group `group.org.openblocker.OpenBlocker`, and NFC (TAG+NDEF) are already in the entitlements. If Xcode reports the Family Controls capability is not enabled on the team, that request is yours to finish in the Apple developer account. Do not skip the prompt on the phone.
5. Choose your iPhone as the run destination. Product > Run.
6. First launch only: iPhone Settings > General > VPN & Device Management > trust the developer certificate, then open Open Blocker.

Do not use `-demo` on the phone if you want to test real keys. Demo seeds fake keys and history.

## First launch

- [ ] App launches without crashing
- [ ] Onboarding completes
- [ ] Family Controls / Screen Time authorization appears and you grant it
- [ ] After that, Settings > Screen Time shows Open Blocker can manage restrictions

## Add keys (Settings > My Keys > Add Key)

### NFC Tag (Open Blocker sticker)

1. Choose **NFC Tag**.
2. Name it.
3. Tap **Start NFC Scan** and hold the sticker to the **top back** of the unlocked iPhone.
4. The app reads the UID and tries to write an Open Blocker NDEF record. If write fails, the sticker still works by UID.
5. Tap **Save Key**.

- [ ] Tag registers and appears under My Keys

### NFC Card (two taps)

1. Choose **NFC Card**.
2. Name it.
3. Tap **First Scan**, hold the card to the top back.
4. Tap **Second Scan**, hold the same card again.
5. Both UIDs must match. Then **Save Key**.
6. If the two UIDs differ, you should see: "Many transit cards, hotel keys and work badges work. Test yours. Many bank cards and phone wallets show a new ID on each tap, so they can't be used." That card cannot be a key.

- [ ] Stable card (transit / hotel / badge) registers after two matching taps
- [ ] A rotating ID (typical bank card or phone wallet) is rejected with that wording

### QR Code

1. Choose **QR Code**.
2. Name it.
3. Tap **Generate QR Code**, then **Save Key**.
4. Share or print the code. Scanning it later uses the camera (grant camera permission).

- [ ] Generated QR blocks and unblocks via **Scan QR** on the Block tab

## Block and unblock

On the Block tab: **Tap or hold to block**. Hold fills the key, then asks for a key. Unblocking always needs a key or an emergency unblock.

If you have both NFC and QR keys, a sheet asks **Tap NFC key** or **Scan QR**. NFC-only skips to the reader. QR-only opens the camera.

- [ ] Idle shows the empty key and "Tap or hold to block"
- [ ] After a successful key, the fill rises and the button reads "Tap to unblock"
- [ ] Selected apps are shielded (Allow Only vs Block mode behaves as configured)
- [ ] The same key unblocks; home returns to idle ("Tap or hold to block", empty key)
- [ ] A key that is not registered does not unblock

### Modes

- [ ] Almost None (Allow Only): selected apps work, others shielded
- [ ] Work Focus / Deep Focus (Block): selected apps shielded, others work

### Schedules

- [ ] Create a schedule 1-2 minutes in the future, turn it on
- [ ] Blocking starts at that time (needs the Monitor extension and a non-Low-Power device)
- [ ] Toggle off stops future fires

This auto-start path has not been verified on a phone.

## Emergency Unblocks

You must already be blocking. There is no 5-second hold on a giant number.

1. Settings > Emergency Unblock
2. You should see five dots, **5 left**, and "One returns every 30 days, up to 5."
3. Tap **Use an emergency unblock**
4. Confirm **Use** (or Cancel)
5. Count becomes **4 left**. Home returns to idle.

If you tap Use while idle, the screen tells you to start a block first.

- [ ] 5 to 4 after confirm, shield clears, home idle
- [ ] Counter survives force-quit (Keychain on a signed device)

## Activity and rules

- [ ] A real session appears on Activity after you unblock
- [ ] Settings > My Rules while blocked: prevent delete, block installs, block purchases, block adult sites, as each toggle claims
- [ ] Screen Time passcode (iPhone Settings) is the strong setup; in-app copy links to Apple's guide

## Known device limits

- App Group may fall back to Application Support if the group container is missing.
- Schedules need background time; Low Power Mode can delay them.
- NFC: unlocked phone, tag at the top back, 1-2 seconds. ISO14443 and ISO15693 only (not FeliCa).
- QR needs camera permission and enough light.
- Many transit cards, hotel keys and work badges work. Test yours. Many bank cards and phone wallets show a new ID on each tap, so they can't be used.

## Troubleshooting

**Build / install**
- Product > Clean Build Folder, then `cd ios && xcodegen generate`
- Trust the developer certificate on the phone
- iOS 16.0+

**NFC**
- iPhone 7 or later, unlocked
- Top back, not the camera bump middle
- Try a known NDEF sticker if a card fails

**No shields**
- Screen Time on, Family Controls granted
- Toggle Screen Time off and on if the first grant was denied

**Emergency**
- Must be in an active block
- Confirm **Use** on the in-screen panel
- On a signed phone the count is Keychain-backed; unsigned simulator builds fall back to UserDefaults

## Suggested order

1. Fresh install, onboarding, Family Controls (5 min)
2. One key of each type you have hardware for (10 min)
3. Block and unblock with each key (15 min)
4. Rules while blocked (10 min)
5. Emergency unblock 5 to 4 (5 min)
6. Activity (5 min)
7. A short future schedule if you have time (overnight if you can)

Physical tags, a stable card, and a printed QR are required for a complete pass.
