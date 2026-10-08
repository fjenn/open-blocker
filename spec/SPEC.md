# Open Blocker Tag Specification v1.0

## Overview

Open Blocker defines a standard NDEF message format for NFC tags used as physical phone blockers. Any app on Android or iOS can read this format to implement tap-to-block functionality.

**Version:** 1.0  
**Date:** October 2026  
**License:** MIT

## Design Goals

1. **Interoperability**: Standard NDEF format readable by Android NFC API and iOS Core NFC
2. **Size**: Fits comfortably on NTAG213 (144 bytes user memory)
3. **Simplicity**: Implementable in an afternoon
4. **App independence**: Works with any blocker app that supports this format

## Security Model

**This tag is a key for honesty, not security.**

NFC tags are not secure storage. Any phone can read and copy the NDEF payload in seconds. The tag's purpose is to create a physical action barrier, not to prevent determined circumvention. Users who want to cheat can:

- Copy the tag with any NFC writing app
- Extract the tag ID and write it to another tag
- Use safe mode, ADB, or uninstall the blocker app (Android)
- Simply not use the blocker

Open Blocker relies on the user's commitment to use the physical action of walking to a tag as a friction mechanism.

**Future work**: NTAG 424 DNA tags support cryptographic authentication that prevents cloning. This could be added in a future version for users who want hardware-enforced blocking.

## NDEF Message Structure

An Open Blocker tag contains a single NDEF message with two records:

### Record 1: External Type Record (Primary Identifier)

- **TNF**: 0x04 (NFC Forum external type)
- **Type**: `openblocker.org:tag` (19 bytes)
- **Payload**: Tag identifier and version
  - Byte 0: Format version (0x01 for v1.0)
  - Bytes 1-16: Random tag ID (16 bytes, 128-bit UUID)

### Record 2: Android Application Record (Optional)

- **TNF**: 0x04 (NFC Forum external type)
- **Type**: `android.com:pkg` (15 bytes)
- **Payload**: Package name in UTF-8, e.g., `app.openblocker.android`

## Rationale

### Why external type domain:name format?

NFC Forum external type records follow the naming convention `domain:typename`, where the domain should be controlled by the issuer. We use `openblocker.org:tag` where `openblocker.org` is the project domain and `tag` identifies this as the tag format record.

This ensures:
- No collision with other NFC applications
- Clear ownership and documentation path
- Standard-compliant naming

### Why external type instead of URI?

We explicitly avoid URI records (especially `https://` URLs) because:

1. **Foqos compatibility**: From reading Foqos's code, Foqos matches tags by chip hardware UID. Avoiding foqos.app URLs means Foqos should fall back to UID matching, so the same tag should also work as a Foqos key. Not yet tested on iPhone.

2. **App independence**: A URI would imply a specific app or web service. External type records are designed for app-specific protocols.

### Why 16-byte random ID?

- Provides 2^128 unique tag IDs (astronomically unlikely collision)
- Allows apps to distinguish between different physical tags
- Enables multi-tag setups (e.g., work tag vs. study tag with different block lists)
- Large enough to be unguessable but fits easily in NTAG213

### Why version byte?

Future-proofs the format. Apps can check the version and handle older tags gracefully if the format evolves.

### Why Android Application Record?

On Android, when a tag with an AAR is tapped, the system prioritizes launching the specified app. This provides a better user experience: tapping the tag opens Open Blocker directly, even if multiple NFC apps are installed.

## Memory Layout

NTAG213 has 144 bytes of user memory (pages 4-39).

**Byte count calculation for Test Vector 1 (with AAR):**

Record 1 (External type with tag ID):
- Flag + TNF byte: 1
- Type length byte: 1
- Payload length byte: 1
- Type string "openblocker.org:tag": 19
- Payload (version + tag ID): 17
- **Record 1 subtotal: 39 bytes**

Record 2 (Android Application Record):
- Flag + TNF byte: 1
- Type length byte: 1
- Payload length byte: 1
- Type string "android.com:pkg": 15
- Payload "app.openblocker.android": 23
- **Record 2 subtotal: 41 bytes**

**Total NDEF message: 80 bytes**

With TLV wrapper:
- TLV type byte: 1
- TLV length byte: 1
- NDEF message: 80
- TLV terminator: 1
- **Total with TLV: 83 bytes**

This leaves **61 bytes of headroom** (144 - 83) for longer package names or future extensions.

**Without AAR (Test Vector 2): 42 bytes total** (39 NDEF + 3 TLV)

## QR Code Encoding

For keys that don't require NFC hardware, Open Blocker defines a QR code encoding:

**Format:** `openblocker://tag/v1/{TAG_ID_HEX}`

Where `{TAG_ID_HEX}` is the 16-byte tag ID encoded as 32 lowercase hexadecimal characters.

**Example:**
```
openblocker://tag/v1/550e8400e29b41d4a716446655440000
```

**Implementation notes:**
- The QR code should encode the complete URL string
- Use QR error correction level H (high, ~30% redundancy)
- The tag ID is the same 16-byte random identifier used in the NDEF format
- Apps decode the URL, extract the hex string, convert to bytes, and use as the tag ID
- Android and iOS both generate printable QR codes of this URI and store the canonical lowercase URI as the key. A QR printed from one app is a valid key on the other.

**Benefits:**
- No NFC hardware required
- Works on devices without NFC support
- Can be printed and placed anywhere
- Multiple copies can be made (though this reduces friction)

## Test Vectors

### Test Vector 1: Minimal Tag

**Tag ID:** `550e8400-e29b-41d4-a716-446655440000` (example UUID)  
**Package:** `app.openblocker.android`

**NDEF Message (hex):**
```
94          // Record 1: MB=1, ME=0, CF=0, SR=1, IL=0, TNF=0x04 (external)
13          // Type length: 19 bytes
11          // Payload length: 17 bytes
6f70656e626c6f636b65722e6f72673a746167  // Type: "openblocker.org:tag"
01          // Payload: version 0x01
550e8400e29b41d4a716446655440000      // Payload: 16-byte tag ID

54          // Record 2: MB=0, ME=1, CF=0, SR=1, IL=0, TNF=0x04
0f          // Type length: 15 bytes
17          // Payload length: 23 bytes
616e64726f69642e636f6d3a706b67          // Type: "android.com:pkg"
6170702e6f70656e626c6f636b65722e616e64726f6964  // Payload: "app.openblocker.android"
```

**Complete NDEF message (wrapped in TLV):**
```
03          // NDEF Message TLV type
XX          // Length (calculated by implementation)
[NDEF message bytes above]
FE          // Terminator TLV
```

### Test Vector 2: Tag Without AAR

**Tag ID:** `f47ac10b-58cc-4372-a567-0e02b2c3d479`  
**Package:** None

**NDEF Message (hex):**
```
D4          // Record 1: MB=1, ME=1, CF=0, SR=1, IL=0, TNF=0x04
13          // Type length: 19 bytes
11          // Payload length: 17 bytes
6f70656e626c6f636b65722e6f72673a746167  // Type: "openblocker.org:tag"
01          // Payload: version 0x01
f47ac10b58cc4372a5670e02b2c3d479      // Payload: 16-byte tag ID
```

## Implementation Notes

### Writing Tags

Use standard NFC libraries:
- **Android**: `android.nfc.NdefMessage` and `android.nfc.NdefRecord`
- **iOS**: `CoreNFC` framework

Generate the 16-byte tag ID using a cryptographically secure random number generator (e.g., `SecureRandom` on Android, `SecRandomCopyBytes` on iOS).

### Reading Tags

1. Read the NDEF message from the tag
2. Verify the first record has TNF=0x04 and type=`openblocker.org:tag`
3. Check the version byte (byte 0 of payload)
4. Extract the 16-byte tag ID (bytes 1-16 of payload)
5. If present, use the AAR for app routing

### Fallback to UID

Apps should also support pairing tags by hardware UID as a fallback. This allows users to repurpose existing NFC tags (keyfobs, cards, etc.) without rewriting them.

## Compatibility

- **Android**: NFC API level 9+ (Android 2.3+)
- **iOS**: Core NFC framework (iOS 13+, in-app reading only; background tag reading not supported for this use case)
- **Tags**: NTAG213, NTAG215, NTAG216, or any ISO 14443-A tag with NDEF support
- **Foqos**: From reading Foqos's code, should be compatible via UID fallback (not yet tested on iPhone)

## Reference Implementation

See `spec/reference/` for a Kotlin encoder/decoder with unit tests covering these test vectors.

## Changelog

### v1.0 (October 2026)
- Initial specification
- External type record with version byte and 16-byte tag ID
- Optional Android Application Record
- Test vectors and reference implementation
