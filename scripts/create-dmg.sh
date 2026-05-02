#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

VERSION="${1:-1.0.0}"
APP_NAME="Facio"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING="dmg-staging"
APP_PATH="dist/${APP_NAME}.app"
DMG_PATH="dist/${DMG_NAME}"
CHECKSUM_PATH="${DMG_PATH}.sha256"
PROVENANCE_PATH="dist/${APP_NAME}-${VERSION}-provenance.txt"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command not found: $1" >&2
        exit 1
    fi
}

cleanup() {
    rm -rf "$STAGING"
}
trap cleanup EXIT

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){2}([-+][0-9A-Za-z.-]+)?$ ]]; then
    echo "Error: invalid version: $VERSION" >&2
    exit 1
fi

require_command hdiutil
require_command shasum
require_command codesign

if [ ! -d "$APP_PATH" ]; then
    echo "Error: missing app bundle: $APP_PATH" >&2
    echo "Run ./scripts/build-app.sh \"$VERSION\" first." >&2
    exit 1
fi

echo "=== Creating DMG ${DMG_NAME} ==="

# Clean
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy app and Applications symlink
cp -r "dist/${APP_NAME}.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create the installation README
cat > "$STAGING/README.txt" << 'README'
INSTALL FACIO

1. Drag Facio.app into the Applications folder.
2. Launch Facio from Applications.

Release builds are signed and notarized before distribution. If macOS blocks
the app, download the latest release again from the official GitHub Releases
page and verify the published SHA-256 checksum before opening an issue.
README

# Create the DMG
hdiutil create -volname "Install Facio" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG_PATH"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    codesign --force --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
    codesign --verify --verbose=2 "$DMG_PATH"
else
    echo "Warning: DMG left without a Developer ID signature because CODESIGN_IDENTITY is unset." >&2
fi

if [ "${NOTARIZE:-0}" = "1" ]; then
    require_command xcrun
    if [ -z "${CODESIGN_IDENTITY:-}" ]; then
        echo "Error: CODESIGN_IDENTITY is required when NOTARIZE=1" >&2
        exit 1
    fi
    : "${APPLE_ID:?APPLE_ID is required when NOTARIZE=1}"
    : "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required when NOTARIZE=1}"
    : "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD is required when NOTARIZE=1}"

    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
fi

shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

{
    echo "artifact=${DMG_NAME}"
    echo "version=${VERSION}"
    echo "sha256=$(awk '{print $1}' "$CHECKSUM_PATH")"
    echo "created_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "git_commit=$(git rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "codesign_identity=${CODESIGN_IDENTITY:-unset}"
    echo "notarized=${NOTARIZE:-0}"
    if command -v swift >/dev/null 2>&1; then
        swift --version | head -n 1 | sed 's/^/swift=/'
    else
        echo "swift=unavailable"
    fi
} > "$PROVENANCE_PATH"

echo "=== DMG created: dist/${DMG_NAME} ==="
echo "SHA256=$(awk '{print $1}' "$CHECKSUM_PATH")"
echo "DMG_NAME=${DMG_NAME}"
