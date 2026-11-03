#!/usr/bin/env bash
# CI only: imports the Developer ID certificate into a throwaway keychain.
#
# Required environment:
#   DEVELOPER_ID_P12_BASE64    base64 of the exported "Developer ID Application" .p12
#   DEVELOPER_ID_P12_PASSWORD  password used when exporting the .p12
#   RUNNER_TEMP                provided by GitHub Actions
#
# Writes CODESIGN_KEYCHAIN to $GITHUB_ENV so later steps sign from this keychain.
set -euo pipefail

: "${DEVELOPER_ID_P12_BASE64:?missing secret DEVELOPER_ID_P12_BASE64}"
: "${DEVELOPER_ID_P12_PASSWORD:?missing secret DEVELOPER_ID_P12_PASSWORD}"
: "${RUNNER_TEMP:?RUNNER_TEMP is not set - this script is meant for GitHub Actions}"

KEYCHAIN_PATH="$RUNNER_TEMP/signing.keychain-db"
CERT_PATH="$RUNNER_TEMP/developer-id.p12"
KEYCHAIN_PASSWORD="$(uuidgen)"

printf '%s' "$DEVELOPER_ID_P12_BASE64" | base64 --decode >"$CERT_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -k "$KEYCHAIN_PATH" -P "$DEVELOPER_ID_P12_PASSWORD" \
  -f pkcs12 -T /usr/bin/codesign -T /usr/bin/security
# Lets codesign use the key without an interactive "allow" prompt.
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
# Keep the login keychain searchable for Apple's intermediate certificates.
# shellcheck disable=SC2046 # word splitting of the keychain list is intended
security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | tr -d '"')

rm -f "$CERT_PATH"

if ! security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -q "Developer ID Application"; then
  echo "error: the imported certificate is not a Developer ID Application identity" >&2
  exit 1
fi

echo "CODESIGN_KEYCHAIN=$KEYCHAIN_PATH" >>"${GITHUB_ENV:-/dev/null}"
echo "Imported Developer ID certificate into $KEYCHAIN_PATH"
