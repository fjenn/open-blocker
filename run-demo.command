#!/bin/bash

# run-demo.command
# Builds Open Blocker and launches it in the simulator with demo data
# Double-click in Finder to run

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PREFERRED_UDID="55E47EC3-2AD7-4E0C-9649-377066331E60"
BUNDLE_ID="org.openblocker.OpenBlocker"

echo "=== Open Blocker Demo Launcher ==="
echo ""

resolve_device() {
    if xcrun simctl list devices available | grep -q "$PREFERRED_UDID"; then
        echo "$PREFERRED_UDID"
        return 0
    fi

    echo "Hard-coded simulator $PREFERRED_UDID is not available." >&2
    echo "Looking up an iPhone 16/17 Pro (or 18 Pro)..." >&2

    local pattern line udid
    for pattern in "iPhone 16 Pro (" "iPhone 17 Pro (" "iPhone 18 Pro ("; do
        line=$(xcrun simctl list devices available | grep -F "$pattern" | grep -v "Pro Max" | head -1 || true)
        if [ -n "${line}" ]; then
            udid=$(printf '%s\n' "$line" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
            if [ -n "${udid}" ]; then
                echo "Using $line" >&2
                echo "$udid"
                return 0
            fi
        fi
    done

    echo "ERROR: No iPhone 16/17/18 Pro simulator is available." >&2
    xcrun simctl list devices available | grep iPhone >&2 || true
    exit 1
}

DEVICE_ID="$(resolve_device)"
echo "Simulator: $DEVICE_ID"
echo ""

# 1. Generate Xcode project
echo "[1/5] Generating Xcode project with XcodeGen..."
cd "$ROOT/ios"
if ! command -v xcodegen &> /dev/null; then
    echo "ERROR: xcodegen not found. Install with: brew install xcodegen"
    exit 1
fi
xcodegen generate
echo "Project generated"
echo ""

# 2. Build for simulator
echo "[2/5] Building for simulator..."
BUILD_DIR="$ROOT/ios/build"
mkdir -p "$BUILD_DIR"
LOG="$BUILD_DIR/demo-build.log"
set +e
xcodebuild -project "Open Blocker.xcodeproj" \
    -scheme OpenBlocker \
    -sdk iphonesimulator \
    -destination "id=$DEVICE_ID" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    build > "$LOG" 2>&1
BUILD_STATUS=$?
set -e
grep -E "BUILD SUCCEEDED|error:|warning:" "$LOG" | head -20 || true
if [ "$BUILD_STATUS" -ne 0 ]; then
    echo "ERROR: Build failed. See $LOG"
    tail -40 "$LOG"
    exit 1
fi
echo "Build succeeded"
echo ""

APP_PATH="$BUILD_DIR/Build/Products/Debug-iphonesimulator/Open Blocker.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Built app not found at $APP_PATH"
    exit 1
fi

# 3. Boot simulator if not running
echo "[3/5] Checking simulator..."
if ! xcrun simctl list devices | grep -q "$DEVICE_ID"; then
    echo "ERROR: Simulator $DEVICE_ID disappeared"
    exit 1
fi
if xcrun simctl list devices | grep "$DEVICE_ID" | grep -q "Booted"; then
    echo "Already booted"
else
    echo "Booting simulator..."
    xcrun simctl boot "$DEVICE_ID"
fi
xcrun simctl bootstatus "$DEVICE_ID" -b

DEVICE_NAME=$(xcrun simctl list devices | grep "$DEVICE_ID" | head -1 | sed -E 's/^[[:space:]]+//; s/ \([0-9A-F-]+\) .*//')
open_visible_simulator_window() {
    local devicehub="/Applications/Xcode.app/Contents/Applications/DeviceHub.app"
    if [ -d "$devicehub" ]; then
        echo "Opening DeviceHub (com.apple.dt.Devices) for $DEVICE_NAME..."
        open -b com.apple.dt.Devices
        open "$devicehub"
        sleep 1
        osascript - "$DEVICE_NAME" <<'APPLESCRIPT'
on run argv
    set deviceName to item 1 of argv
    tell application "System Events"
        tell process "DeviceHub"
            set frontmost to true
            delay 0.6
            tell menu bar item "Window" of menu bar 1
                click
                delay 0.3
                tell menu 1
                    set n to count of menu items
                    repeat with i from 1 to n
                        try
                            set nm to name of menu item i
                            if nm is not missing value and nm contains (deviceName & " (") then
                                click menu item i
                                return "showed " & nm
                            end if
                        end try
                    end repeat
                end tell
            end tell
        end tell
    end tell
    return "DeviceHub open (no Window menu match for " & deviceName & ")"
end run
APPLESCRIPT
        return
    fi

    local developer_dir simulator_app candidate
    developer_dir="$(xcode-select -p)"
    simulator_app=""
    for candidate in \
        "$developer_dir/Applications/Simulator.app" \
        "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
    do
        if [ -d "$candidate" ]; then
            simulator_app="$candidate"
            break
        fi
    done
    if [ -n "$simulator_app" ]; then
        echo "Opening Simulator.app..."
        open "$simulator_app"
    elif open -a Simulator 2>/dev/null; then
        echo "Opened Simulator.app"
    else
        echo "ERROR: Neither DeviceHub.app nor Simulator.app is installed. Finn will not see a window."
        exit 1
    fi
}

open_visible_simulator_window
echo "Simulator ready"
echo ""

# 4. Install app
echo "[4/5] Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
echo "App installed"
echo ""

# 5. Launch with demo data
echo "[5/5] Launching with demo data..."
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" -demo
echo "App launched"
# Bring the viewer back in front so Finn sees Open Blocker, not Terminal.
osascript -e 'tell application "System Events" to tell process "DeviceHub" to set frontmost to true' 2>/dev/null || true
echo ""

echo "=== Demo is running! ==="
echo "The app should now be visible in the simulator with demo data:"
echo "  - 3 modes (Almost None, Work Focus, Deep Focus)"
echo "  - 3 keys (Desk Key, Keychain Card, Gym QR)"
echo "  - 2 schedules (Work Hours, Evening Focus)"
echo "  - 2 weeks of activity history, including a finished session today"
echo ""
