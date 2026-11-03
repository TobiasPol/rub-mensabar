#!/usr/bin/env bash
# Points Casks/rub-mensabar.rb at a new release.
#
# usage: script/update_cask.sh <version> <sha256>
set -euo pipefail

VERSION="${1:?usage: $0 <version> <sha256>}"
SHA256="${2:?usage: $0 <version> <sha256>}"
CASK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Casks/rub-mensabar.rb"

if [[ ! "$SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "error: '$SHA256' is not a sha256 hex digest" >&2
  exit 2
fi

VERSION="$VERSION" SHA256="$SHA256" perl -pi -e '
  s/^  version ".*"$/  version "$ENV{VERSION}"/;
  s/^  sha256 ".*"$/  sha256 "$ENV{SHA256}"/;
' "$CASK"

if ! grep -q "version \"$VERSION\"" "$CASK" || ! grep -q "sha256 \"$SHA256\"" "$CASK"; then
  echo "error: failed to update $CASK" >&2
  exit 1
fi
