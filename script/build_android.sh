#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/AndroidApp"
BUILD_DIR="$APP_DIR/build"

ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"
BUILD_TOOLS="$ANDROID_HOME/build-tools/34.0.0"
ANDROID_JAR="$ANDROID_HOME/platforms/android-34/android.jar"

AAPT2="$BUILD_TOOLS/aapt2"
D8="$BUILD_TOOLS/d8"
ZIPALIGN="$BUILD_TOOLS/zipalign"
APKSIGNER="$BUILD_TOOLS/apksigner"
JAVAC="$JAVA_HOME/bin/javac"
KEYTOOL="$JAVA_HOME/bin/keytool"

for tool in "$AAPT2" "$D8" "$ZIPALIGN" "$APKSIGNER" "$JAVAC" "$KEYTOOL" "$ANDROID_JAR"; do
    [ -e "$tool" ] || { echo "missing: $tool" >&2; exit 1; }
done

rm -rf "$BUILD_DIR/classes" "$BUILD_DIR/dex" "$BUILD_DIR/generated"
mkdir -p "$BUILD_DIR/classes" "$BUILD_DIR/dex" "$BUILD_DIR/generated" "$BUILD_DIR/outputs/apk/debug"

"$AAPT2" link \
    --manifest "$APP_DIR/src/main/AndroidManifest.xml" \
    -I "$ANDROID_JAR" \
    --java "$BUILD_DIR/generated" \
    --min-sdk-version 26 \
    --target-sdk-version 34 \
    -o "$BUILD_DIR/base.apk"

find "$APP_DIR/src/main/java" "$BUILD_DIR/generated" -name '*.java' | sort > "$BUILD_DIR/java-sources.txt"
"$JAVAC" -encoding UTF-8 -source 8 -target 8 -bootclasspath "$ANDROID_JAR" -d "$BUILD_DIR/classes" @"$BUILD_DIR/java-sources.txt"
"$D8" --min-api 26 --output "$BUILD_DIR/dex" $(find "$BUILD_DIR/classes" -name '*.class' | sort)

cp "$BUILD_DIR/base.apk" "$BUILD_DIR/unsigned.apk"
(cd "$BUILD_DIR/dex" && zip -q -r "$BUILD_DIR/unsigned.apk" classes.dex)
if [ -d "$APP_DIR/src/main/assets" ]; then
    (cd "$APP_DIR/src/main" && zip -q -r "$BUILD_DIR/unsigned.apk" assets)
fi

"$ZIPALIGN" -f -p 4 "$BUILD_DIR/unsigned.apk" "$BUILD_DIR/aligned.apk"

KEYSTORE="$BUILD_DIR/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    "$KEYTOOL" -genkeypair \
        -keystore "$KEYSTORE" \
        -storepass android \
        -keypass android \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Android Debug,O=SwiftManchu,C=US"
fi

APK="$BUILD_DIR/outputs/apk/debug/SwiftManchu-debug.apk"
"$APKSIGNER" sign \
    --ks "$KEYSTORE" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out "$APK" \
    "$BUILD_DIR/aligned.apk"
"$APKSIGNER" verify --min-sdk-version 26 "$APK"

echo "$APK"
