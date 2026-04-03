#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
APP_NAME="Facio"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING="dmg-staging"

echo "=== Creating DMG ${DMG_NAME} ==="

# Clean
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy app and Applications symlink
cp -r "dist/${APP_NAME}.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create the installation README
cat > "$STAGING/README.txt" << 'README'
╔══════════════════════════════════════════════════════════╗
║                    INSTALL FACIO                         ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  1. Drag Facio.app into the Applications folder          ║
║                                                          ║
║  2. macOS will block the app on first launch.            ║
║     This is normal — the app is not signed yet.          ║
║                                                          ║
║     To authorize it:                                     ║
║     → Open System Settings > Privacy & Security          ║
║     → Scroll down to the Security section                ║
║     → Click "Open Anyway" next to the Facio message      ║
║     → Confirm by clicking "Open"                         ║
║                                                          ║
║     Alternative (Terminal):                              ║
║     xattr -cr /Applications/Facio.app                    ║
║     Then launch Facio normally.                          ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
README

# Create the DMG
hdiutil create -volname "Install Facio" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "dist/${DMG_NAME}"

# Clean up
rm -rf "$STAGING"

echo "=== DMG created: dist/${DMG_NAME} ==="
echo "DMG_NAME=${DMG_NAME}"
