#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version>" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="RUBMensaBar"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/dist/$APP_NAME-v$VERSION.zip"

cd "$ROOT_DIR"

RUB_MENSABAR_VERSION="$VERSION" ./script/build_and_run.sh --no-launch >/dev/null

/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
/usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

shasum -a 256 "$ZIP_PATH"
