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

# Creer le README d'installation
cat > "$STAGING/LISEZ-MOI.txt" << 'README'
╔═══════════════════════════════════════════════════════╗
║                  INSTALLER FACIO                       ║
╠═══════════════════════════════════════════════════════╣
║                                                        ║
║  1. Glissez Facio.app vers le dossier Applications     ║
║                                                        ║
║  2. Au premier lancement, macOS peut bloquer l'app.    ║
║     C'est normal (l'app n'est pas encore certifiee).   ║
║                                                        ║
║     Pour l'ouvrir :                                    ║
║     → Clic droit sur Facio.app > Ouvrir                ║
║     → Cliquez "Ouvrir" dans la fenetre de confirmation ║
║                                                        ║
║     Si ca ne marche pas, ouvrez le Terminal et tapez : ║
║     xattr -cr /Applications/Facio.app                  ║
║     Puis relancez Facio normalement.                   ║
║                                                        ║
╚═══════════════════════════════════════════════════════╝
README

# Creer le DMG
hdiutil create -volname "Facio — Glissez vers Applications" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "dist/${DMG_NAME}"

# Nettoyer
rm -rf "$STAGING"

echo "=== DMG cree : dist/${DMG_NAME} ==="
echo "DMG_NAME=${DMG_NAME}"
