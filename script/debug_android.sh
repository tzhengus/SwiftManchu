#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-192.168.4.27:5555}"
APK="$ROOT/AndroidApp/build/outputs/apk/debug/SwiftManchu-debug.apk"

"$ROOT/script/build_android.sh"
adb connect "$DEVICE"
adb -s "$DEVICE" install -r "$APK"
adb -s "$DEVICE" shell am start -n com.tzheng.swiftmanchu/.MainActivity

echo "Android $(adb -s "$DEVICE" shell getprop ro.build.version.release | tr -d '\r') / SDK $(adb -s "$DEVICE" shell getprop ro.build.version.sdk | tr -d '\r')"
