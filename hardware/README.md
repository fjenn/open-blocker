# Hardware

**The Android 0.1.0-alpha app has not been tested on real devices.** NFC write and read are emulator-unproven. These files are for people who want to print a case and try a tag; please report results in GitHub Issues or Discussions.

## Tag

- **NTAG213**, 25 mm round sticker (ISO 14443-A, 13.56 MHz, 144 bytes user memory)
- Optional **10 mm diameter x 2 mm** disc magnet in the case pocket

NTAG215/216 also fit the format. Avoid MIFARE Classic (poor iPhone Core NFC support) and unlabeled "NFC tags".

Not every card works. Test yours. Bank cards and phone wallets often show a new ID on each tap.

## 3D case (no supports)

- `case.scad` (OpenSCAD)
- `openblocker-key-25mm.stl` (print this)

Print the STL flat on the bed, no supports. 0.2 mm layers, about 20% infill. The top well is for a 25 mm NTAG213 sticker. The bottom well is for an optional 10x2 mm magnet.

```bash
openscad -o openblocker-key-25mm.stl case.scad
```

## QR instead of NFC

The apps can generate a printable QR (`openblocker://tag/v1/` plus 32 hex characters). Real-camera register / start / end is not device-tested yet.

## Foqos

From reading Foqos's code, the same tag also works as your key in Foqos on iPhone (UID matching). Not yet tested on iPhone.
