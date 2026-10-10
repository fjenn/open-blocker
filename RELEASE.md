# Releasing Open Blocker

**0.2.0-alpha is an early alpha, not tested on real devices.** NFC and QR keys have been tried on an Android emulator only. Release notes and the README must keep that sentence near the top. Invite testers to file Issues or Discussions. Do not frame a release as ready for daily use.

## Version

- Android `versionName`: `0.2.0-alpha`
- Android `versionCode`: `2`

Public notes: `RELEASE-NOTES-0.2.0-alpha.md` (GitHub Release body) and `CHANGELOG.md`.

## Signed APK

The release keystore is **not** in git. It lives in `artifacts/release-signing/` on the machine that generated it (gitignored).

```bash
export OPENBLOCKER_KEYSTORE_PATH=/path/to/openblocker-release.jks
export OPENBLOCKER_KEYSTORE_PASSWORD=...
export OPENBLOCKER_KEY_ALIAS=openblocker
export OPENBLOCKER_KEY_PASSWORD=...
cd android
./build-release.sh --release-only
```

Outputs:

- `android/dist/openblocker-0.2.0-alpha.apk` (CI attaches this on tag `v*`)
- `artifacts/release/open-blocker-0.2.0-alpha.apk` and `.sha256`

Verify:

```bash
apksigner verify --print-certs artifacts/release/open-blocker-0.2.0-alpha.apk
```

## GitHub secrets (tag `v*` job)

Set these on the public GitHub repo so `.github/workflows/build.yml` `release` can sign the same way:

- `OPENBLOCKER_KEYSTORE_BASE64`
- `OPENBLOCKER_KEYSTORE_PASSWORD`
- `OPENBLOCKER_KEY_ALIAS` (`openblocker`)
- `OPENBLOCKER_KEY_PASSWORD`

Push tag `v0.2.0-alpha`. If `OPENBLOCKER_KEYSTORE_BASE64` is missing, the job prints a skip message and does not publish an APK.

Values to paste are in the private `artifacts/release-signing/` folder, not in this repo.

## Wording

- No "first", no "Foqos supports Open Blocker"
- Allowed Foqos line only with untested hedge
- Prefer "Not every card works. Test yours."
- No em dashes
- No anti-clone or security-lock claims
