#!/usr/bin/env bash
# Builds, signs, notarizes and zips a release of RUBMensaBar.app.
#
# usage: script/package_release.sh <version>      e.g. 0.2.0 or 0.2.0-beta.1
#
# Signing (first match wins):
#   CODESIGN_IDENTITY        identity name or SHA-1; "-" forces an ad-hoc build
#   (default)                first "Developer ID Application" identity in the keychain
#   CODESIGN_KEYCHAIN        optional keychain to search (used by CI)
#
# Notarization (skipped with a warning when neither is configured):
#   NOTARY_KEYCHAIN_PROFILE  profile stored via `xcrun notarytool store-credentials`
#   NOTARY_API_KEY_PATH + NOTARY_API_KEY_ID + NOTARY_API_ISSUER_ID
#                            App Store Connect API key (used by CI)
#   REQUIRE_NOTARIZATION=1   fail instead of producing an un-notarized build
set -euo pipefail

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]]; then
  echo "usage: $0 <version>   (e.g. 0.2.0 or 0.2.0-beta.1)" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="RUBMensaBar"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-v$VERSION.zip"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

log() { printf '\n==> %s\n' "$*" >&2; }
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- Build -------------------------------------------------------------------
log "Building $APP_NAME $VERSION (release, universal)"
APP_BUNDLE="$(RUB_MENSABAR_VERSION="$VERSION" "$ROOT_DIR/script/build_app.sh" release)"
/usr/bin/lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME" >&2

# --- Sign --------------------------------------------------------------------
KEYCHAIN_ARGS=()
[[ -n "${CODESIGN_KEYCHAIN:-}" ]] && KEYCHAIN_ARGS=(--keychain "$CODESIGN_KEYCHAIN")

IDENTITY="${CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(/usr/bin/security find-identity -v -p codesigning ${CODESIGN_KEYCHAIN:+"$CODESIGN_KEYCHAIN"} \
    | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -n 1)"
fi

if [[ -z "$IDENTITY" || "$IDENTITY" == "-" ]]; then
  [[ "${REQUIRE_NOTARIZATION:-0}" == "1" ]] && fail "no Developer ID Application identity found"
  log "Signing ad-hoc (no Developer ID identity) - this build will trigger Gatekeeper warnings"
  /usr/bin/codesign --force --sign - "$APP_BUNDLE"
  ADHOC=1
else
  log "Signing with: $IDENTITY"
  # Hardened runtime + secure timestamp are both mandatory for notarization.
  /usr/bin/codesign --force --options runtime --timestamp \
    ${KEYCHAIN_ARGS[@]+"${KEYCHAIN_ARGS[@]}"} --sign "$IDENTITY" "$APP_BUNDLE"
  ADHOC=0
fi

log "Verifying signature"
/usr/bin/codesign --verify --strict --verbose=2 "$APP_BUNDLE"
if [[ "$ADHOC" == "0" ]]; then
  SIGNATURE_INFO="$(/usr/bin/codesign --display --verbose=4 "$APP_BUNDLE" 2>&1)"
  grep -q "Authority=Developer ID Application" <<<"$SIGNATURE_INFO" || fail "not signed with a Developer ID certificate"
  grep -q "flags=.*runtime" <<<"$SIGNATURE_INFO" || fail "hardened runtime is not enabled"
  grep -q "^Timestamp=" <<<"$SIGNATURE_INFO" || fail "signature has no secure timestamp"
fi

# --- Notarize ----------------------------------------------------------------
NOTARY_ARGS=()
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  NOTARY_ARGS=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [[ -n "${NOTARY_API_KEY_PATH:-}" && -n "${NOTARY_API_KEY_ID:-}" && -n "${NOTARY_API_ISSUER_ID:-}" ]]; then
  NOTARY_ARGS=(--key "$NOTARY_API_KEY_PATH" --key-id "$NOTARY_API_KEY_ID" --issuer "$NOTARY_API_ISSUER_ID")
fi

if [[ "$ADHOC" == "0" && ${#NOTARY_ARGS[@]} -gt 0 ]]; then
  log "Submitting to Apple notary service (this usually takes a few minutes)"
  SUBMIT_ZIP="$WORK_DIR/$APP_NAME-notarize.zip"
  RESULT_JSON="$WORK_DIR/notary-result.json"
  /usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$SUBMIT_ZIP"

  xcrun notarytool submit "$SUBMIT_ZIP" "${NOTARY_ARGS[@]}" \
    --wait --timeout 30m --output-format json >"$RESULT_JSON" || true

  STATUS="$(/usr/bin/plutil -extract status raw -o - "$RESULT_JSON" 2>/dev/null || echo unknown)"
  SUBMISSION_ID="$(/usr/bin/plutil -extract id raw -o - "$RESULT_JSON" 2>/dev/null || true)"
  echo "Notarization status: $STATUS (submission ${SUBMISSION_ID:-n/a})" >&2

  if [[ "$STATUS" != "Accepted" ]]; then
    cat "$RESULT_JSON" >&2 || true
    [[ -n "$SUBMISSION_ID" ]] && xcrun notarytool log "$SUBMISSION_ID" "${NOTARY_ARGS[@]}" >&2 || true
    fail "notarization failed"
  fi

  log "Stapling notarization ticket"
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"

  log "Gatekeeper assessment"
  /usr/sbin/spctl --assess --type execute --verbose=4 "$APP_BUNDLE"
  NOTARIZED=1
else
  [[ "${REQUIRE_NOTARIZATION:-0}" == "1" ]] && fail "notarization credentials are not configured"
  log "Skipping notarization (no credentials configured)"
  NOTARIZED=0
fi

# --- Package -----------------------------------------------------------------
log "Creating $(basename "$ZIP_PATH")"
rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"
/usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
(cd "$DIST_DIR" && shasum -a 256 "$(basename "$ZIP_PATH")" >"$(basename "$ZIP_PATH").sha256")
SHA256="$(cut -d ' ' -f 1 "$ZIP_PATH.sha256")"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "zip=$ZIP_PATH"
    echo "sha256=$SHA256"
    echo "notarized=$NOTARIZED"
  } >>"$GITHUB_OUTPUT"
fi

echo "$ZIP_PATH"
echo "sha256: $SHA256"
echo "notarized: $([[ "$NOTARIZED" == "1" ]] && echo yes || echo no)"
