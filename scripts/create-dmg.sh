#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
APP_NAME="Facio"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING="dmg-staging"

echo "=== Creation du DMG ${DMG_NAME} ==="

# Nettoyer
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copier l'app et le lien Applications
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
║     Or double-click "Open Security Settings" in this     ║
║     window to go there directly.                         ║
║                                                          ║
║     Alternative (Terminal):                              ║
║     xattr -cr /Applications/Facio.app                    ║
║     Then launch Facio normally.                          ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
README

# Create a small app that opens Privacy & Security settings directly
osacompile -o "$STAGING/Open Security Settings.app" \
  -e 'do shell script "open \"x-apple.systempreferences:com.apple.settings.PrivacySecurity\""'

# Set gear icon for the Security Settings app
GEAR_ICON="/System/Applications/System Settings.app/Contents/Resources/SystemSettings.icns"
if [ -f "$GEAR_ICON" ]; then
  rm -f "$STAGING/Open Security Settings.app/Contents/Resources/Assets.car"
  cp "$GEAR_ICON" "$STAGING/Open Security Settings.app/Contents/Resources/applet.icns"
fi

# Creer le DMG
hdiutil create -volname "Facio — Glissez vers Applications" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "dist/${DMG_NAME}"

# Nettoyer
rm -rf "$STAGING"

echo "=== DMG cree : dist/${DMG_NAME} ==="
echo "DMG_NAME=${DMG_NAME}"
