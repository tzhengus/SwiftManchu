#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SwiftManchu"
BUNDLE_ID="com.tianzheng.SwiftManchu"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-module-cache"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [[ ! -d "$SDK" ]]; then
  SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
fi

DIRECT_BUILD="$ROOT_DIR/.build/direct"
rm -rf "$DIRECT_BUILD"
mkdir -p "$DIRECT_BUILD"

swiftc -sdk "$SDK" \
  -parse-as-library \
  -emit-library \
  -static \
  -emit-module \
  -module-name SwiftManchuCore \
  Sources/SwiftManchuCore/*.swift \
  -o "$DIRECT_BUILD/libSwiftManchuCore.a" \
  -emit-module-path "$DIRECT_BUILD/SwiftManchuCore.swiftmodule"

swiftc -sdk "$SDK" \
  -parse-as-library \
  -I "$DIRECT_BUILD" \
  -L "$DIRECT_BUILD" \
  -lSwiftManchuCore \
  Sources/SwiftManchu/App/*.swift \
  Sources/SwiftManchu/Models/*.swift \
  Sources/SwiftManchu/Support/*.swift \
  Sources/SwiftManchu/Views/*.swift \
  -lsqlite3 \
  -o "$DIRECT_BUILD/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$DIRECT_BUILD/$APP_NAME" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp Sources/SwiftManchu/Resources/ManchuDict.SQLite "$APP_RESOURCES/"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
