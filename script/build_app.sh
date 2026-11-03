#!/usr/bin/env bash
# Builds dist/RUBMensaBar.app from the SwiftPM executable. Does not sign.
#
# usage: script/build_app.sh [debug|release]
#
# Environment:
#   RUB_MENSABAR_VERSION  marketing version, e.g. 0.2.0-beta.1 (default: latest git tag)
#   RUB_MENSABAR_BUILD    monotonically increasing build number (default: git commit count)
#   RUB_MENSABAR_ARCHS    space separated archs for release builds (default: "arm64 x86_64")
set -euo pipefail

CONFIGURATION="${1:-debug}"
APP_NAME="RUBMensaBar"
BUNDLE_ID="de.tobiaspolley.RUBMensaBar"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
SWIFTPM_CACHE="$ROOT_DIR/.build/swiftpm-cache"

cd "$ROOT_DIR"

default_version() {
  local tag
  tag="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
  if [[ -n "$tag" ]]; then
    echo "${tag#v}"
  else
    echo "0.0.0-dev"
  fi
}

APP_VERSION="${RUB_MENSABAR_VERSION:-$(default_version)}"
APP_SHORT_VERSION="${APP_VERSION%%-*}"
APP_BUILD="${RUB_MENSABAR_BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

if [[ ! "$APP_SHORT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version '$APP_VERSION' must look like 1.2.3 or 1.2.3-beta.1" >&2
  exit 2
fi

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFTPM_CACHE"

BUILD_ARGS=(--disable-sandbox --cache-path "$SWIFTPM_CACHE" -c "$CONFIGURATION")
case "$CONFIGURATION" in
  debug) ;;
  release)
    for arch in ${RUB_MENSABAR_ARCHS:-arm64 x86_64}; do
      BUILD_ARGS+=(--arch "$arch")
    done
    ;;
  *)
    echo "usage: $0 [debug|release]" >&2
    exit 2
    ;;
esac

swift build "${BUILD_ARGS[@]}" --product "$APP_NAME" >&2
BUILD_BINARY="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_MACOS/$APP_NAME"
chmod +x "$APP_MACOS/$APP_NAME"

cat >"$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>de</string>
  <key>CFBundleDisplayName</key>
  <string>RUB MensaBar</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>RUB MensaBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_SHORT_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>RUBMensaBarVersion</key>
  <string>$APP_VERSION</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>© $(date +%Y) Tobias Polley</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$APP_CONTENTS/Info.plist" >/dev/null
echo "$APP_BUNDLE"
