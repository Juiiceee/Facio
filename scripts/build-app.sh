#!/bin/bash
set -e

# === Configuration ===
APP_NAME="Facio"
VERSION="${1:-1.0.0}"
BUNDLE_ID="com.juiceeedev.facio"
BUILD_DIR=".build/release"
APP_DIR="dist/${APP_NAME}.app"

echo "=== Building ${APP_NAME} v${VERSION} ==="

# 1. Build en release
echo "[1/4] Compilation en mode release..."
swift build -c release 2>&1

EXECUTABLE="${BUILD_DIR}/${APP_NAME}"
if [ ! -f "$EXECUTABLE" ]; then
    echo "Erreur: executable non trouve a $EXECUTABLE"
    exit 1
fi

# 2. Creer la structure .app
echo "[2/4] Creation du bundle .app..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 3. Copier l'executable
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/${APP_NAME}"

# 4. Creer Info.plist
echo "[3/4] Generation du Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Facio</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.business</string>
</dict>
</plist>
PLIST

# 5. Copier l'icone
if [ -f "Facio/Resources/AppIcon.icns" ]; then
    cp "Facio/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "    Icone copiee."
else
    echo "    Pas d'icone trouvee, generation..."
    swift scripts/generate-icon.swift 2>&1 || true
    if [ -f "Facio/Resources/AppIcon.icns" ]; then
        cp "Facio/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    fi
fi

# 6. Creer PkgInfo
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

# 7. Signer l'app (ad-hoc si pas de certificat)
echo "[4/5] Signature de l'app..."
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    codesign --force --deep --sign "$CODESIGN_IDENTITY" \
        --options runtime \
        --entitlements "scripts/Facio.entitlements" \
        "$APP_DIR" 2>&1
    echo "    Signe avec: $CODESIGN_IDENTITY"
else
    codesign --force --deep --sign - "$APP_DIR" 2>&1
    echo "    Signature ad-hoc (pas de certificat Developer ID)"
fi

echo "[5/5] Termine !"
echo ""
echo "=== ${APP_NAME}.app cree dans dist/ ==="
echo "Pour l'utiliser :"
echo "  open dist/${APP_NAME}.app"
echo ""
echo "Pour l'installer :"
echo "  cp -r dist/${APP_NAME}.app /Applications/"
echo ""
echo "Taille: $(du -sh "$APP_DIR" | cut -f1)"
