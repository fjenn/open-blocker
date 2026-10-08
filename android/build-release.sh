#!/bin/bash
# Build Open Blocker Android APKs.
# Usage:
#   ./build-release.sh                 # production APK, then TEST_MODE APK
#   ./build-release.sh --release-only  # production APK only (for GitHub Releases)
#   ./build-release.sh --test-only     # TEST_MODE APK only
#
# If OPENBLOCKER_KEYSTORE_PATH, OPENBLOCKER_KEYSTORE_PASSWORD,
# OPENBLOCKER_KEY_ALIAS, and OPENBLOCKER_KEY_PASSWORD are all set and the
# keystore file exists, the APK is signed with that release key.
# Otherwise the APK is signed with the Android debug key and named
# *-debug-signed.apk so it is obvious this is not a store key.
#
# Do not generate or commit a release keystore in this repository.

set -euo pipefail

BUILD_TEST_ONLY=false
RELEASE_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --test-only) BUILD_TEST_ONLY=true ;;
        --release-only) RELEASE_ONLY=true ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--release-only|--test-only]"
            exit 1
            ;;
    esac
done

cd "$(dirname "$0")"

VERSION=$(sed -n 's/.*versionName = "\([^"]*\)".*/\1/p' app/build.gradle.kts | head -1)
if [ -z "$VERSION" ]; then
    echo "Could not read versionName from app/build.gradle.kts"
    exit 1
fi

mkdir -p dist ../artifacts

has_release_keystore=false
if [ -n "${OPENBLOCKER_KEYSTORE_PATH:-}" ] && \
   [ -n "${OPENBLOCKER_KEYSTORE_PASSWORD:-}" ] && \
   [ -n "${OPENBLOCKER_KEY_ALIAS:-}" ] && \
   [ -n "${OPENBLOCKER_KEY_PASSWORD:-}" ]; then
    if [ ! -f "$OPENBLOCKER_KEYSTORE_PATH" ]; then
        echo "OPENBLOCKER_KEYSTORE_PATH does not exist: $OPENBLOCKER_KEYSTORE_PATH"
        exit 1
    fi
    has_release_keystore=true
fi

write_sha256() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | tee "${file}.sha256"
    else
        shasum -a 256 "$file" | tee "${file}.sha256"
    fi
}

copy_apk() {
    local src="$1"
    local dest_name="$2"
    local public_copy="${3:-}"
    if [ ! -f "$src" ]; then
        echo "Build failed: APK not found at $src"
        exit 1
    fi
    mkdir -p dist ../artifacts
    cp "$src" "dist/$dest_name"
    cp "$src" "../artifacts/$dest_name"
    write_sha256 "dist/$dest_name" > /dev/null
    cp "dist/${dest_name}.sha256" "../artifacts/${dest_name}.sha256"
    echo "APK: dist/$dest_name"
    echo "SHA256: $(cat "dist/${dest_name}.sha256")"
    if [ -n "$public_copy" ]; then
        mkdir -p ../artifacts/release
        cp "$src" "../artifacts/release/$public_copy"
        write_sha256 "../artifacts/release/$public_copy" > /dev/null
        echo "Public APK: ../artifacts/release/$public_copy"
    fi
}

build_production() {
    echo "Building Open Blocker $VERSION (TEST_MODE off)..."
    unset OPENBLOCKER_TEST_MODE || true
    ./gradlew assembleRelease --no-daemon

    local src="app/build/outputs/apk/release/app-release.apk"
    local dest
    if [ "$has_release_keystore" = true ]; then
        dest="openblocker-${VERSION}.apk"
        echo "Signed with release keystore."
        copy_apk "$src" "$dest" "open-blocker-${VERSION}.apk"
    else
        dest="openblocker-${VERSION}-debug-signed.apk"
        echo "OPENBLOCKER_KEYSTORE_* is not set."
        echo "Producing a debug-signed APK for device testing: $dest"
        echo "This is not a production signing key."
        echo "For GitHub Releases, set the four OPENBLOCKER_KEYSTORE_* variables."
        copy_apk "$src" "$dest"
    fi
}

build_test() {
    echo "Building Open Blocker $VERSION (TEST_MODE on)..."
    export OPENBLOCKER_TEST_MODE=1
    ./gradlew assembleRelease --no-daemon
    unset OPENBLOCKER_TEST_MODE || true

    local src="app/build/outputs/apk/release/app-release.apk"
    local dest
    if [ "$has_release_keystore" = true ]; then
        dest="openblocker-${VERSION}-test.apk"
    else
        dest="openblocker-${VERSION}-test-debug-signed.apk"
    fi
    copy_apk "$src" "$dest"
    echo "TEST_MODE is on in this APK. It includes a Quick Test button. Do not ship it."
}

if [ "$BUILD_TEST_ONLY" = false ]; then
    build_production
fi

if [ "$RELEASE_ONLY" = false ]; then
    build_test
fi
