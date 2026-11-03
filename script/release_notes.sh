#!/usr/bin/env bash
# Prints the CHANGELOG.md section for a version; fails if there is none, so a
# release can't go out without notes.
#
# usage: script/release_notes.sh <version>
set -euo pipefail

VERSION="${1:?usage: $0 <version>}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NOTES="$(awk -v heading="## v$VERSION" '
  $0 == heading { found = 1; next }
  found && /^## / { exit }
  found { print }
' "$ROOT_DIR/CHANGELOG.md" | sed -e '/./,$!d')"

if [[ -z "${NOTES//[[:space:]]/}" ]]; then
  echo "error: CHANGELOG.md has no '## v$VERSION' section" >&2
  exit 1
fi

printf '%s\n' "$NOTES"
