#!/usr/bin/env bash
# make_app.sh — builds CC2PDF.app and signs it locally (ad-hoc)
# Usage: ./make_app.sh
set -euo pipefail

PRODUCT_NAME="CC2PDF"
BUNDLE_ID="com.cc2pdf.app"
VERSION="1.0"
MIN_MACOS="14.0"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${REPO_DIR}/.build/release"
DIST_DIR="${REPO_DIR}/dist"
APP_DIR="${DIST_DIR}/${PRODUCT_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"
ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
ICON_PNG="${BUILD_DIR}/AppIcon.png"
ICON_ICNS="${BUILD_DIR}/AppIcon.icns"

echo "==> Building release binary…"
cd "${REPO_DIR}"
swift build -c release

echo "==> Generating app icon…"
swift Tools/make_icon.swift "${ICON_PNG}"

echo "==> Creating iconset…"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

# Standard sizes required by iconutil
for SIZE in 16 32 128 256 512; do
    sips -z ${SIZE} ${SIZE} "${ICON_PNG}" --out "${ICONSET_DIR}/icon_${SIZE}x${SIZE}.png" > /dev/null
done

for SIZE in 32 64 256 512 1024; do
    HALF=$((SIZE / 2))
    sips -z ${SIZE} ${SIZE} "${ICON_PNG}" --out "${ICONSET_DIR}/icon_${HALF}x${HALF}@2x.png" > /dev/null
done

iconutil -c icns "${ICONSET_DIR}" -o "${ICON_ICNS}"

echo "==> Assembling .app bundle…"
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${PRODUCT_NAME}" "${MACOS_DIR}/${PRODUCT_NAME}"
cp "${ICON_ICNS}" "${RESOURCES_DIR}/AppIcon.icns"

cat > "${CONTENTS}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>CC2PDF</string>
    <key>CFBundleDisplayName</key>
    <string>CC2PDF</string>
    <key>CFBundleIdentifier</key>
    <string>com.cc2pdf.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>CC2PDF</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

# Replace placeholders substituted at build time
sed -i '' \
    "s|com.cc2pdf.app|${BUNDLE_ID}|g;
     s|<string>1.0</string>|<string>${VERSION}</string>|g;
     s|<string>14.0</string>|<string>${MIN_MACOS}</string>|g" \
    "${CONTENTS}/Info.plist"

echo "==> Signing ad-hoc (locally)…"
codesign --force --deep --sign - "${APP_DIR}"

echo ""
echo "✅  Built: ${APP_DIR}"
echo "    Run:   open \"${APP_DIR}\""
echo "    Or:    open dist/"
