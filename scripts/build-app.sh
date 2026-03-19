#!/bin/bash
# Build script for Inti.app
# Usage: ./scripts/build-app.sh
# Output: build/Inti.app

set -e

APP_NAME="Inti"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "🔨 Building ${APP_NAME} in release mode..."
swift build -c release

echo "📦 Creating app bundle..."
# Clean previous build
rm -rf "${APP_BUNDLE}"

# Create directory structure
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Copy executable
cp ".build/release/${APP_NAME}" "${MACOS}/${APP_NAME}"

# Copy Info.plist
cp "Info.plist" "${CONTENTS}/Info.plist"

# Copy icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES}/AppIcon.icns"
    echo "🎨 App icon included"
fi

echo "🔏 Signing app bundle..."
# Ad-hoc code signing makes the app distributable without an Apple Developer account.
# Without this, macOS Gatekeeper shows "app is damaged" when downloaded from the internet.
codesign --force --deep --sign - "${APP_BUNDLE}"

# Verify signature
codesign --verify --verbose "${APP_BUNDLE}" && echo "✅ Signature verified" || echo "⚠️  Signature verification failed"

echo ""
echo "✅ ${APP_NAME}.app created at: ${APP_BUNDLE}"
echo ""
echo "To install, drag ${APP_NAME}.app to /Applications"
echo "Or run directly: open ${APP_BUNDLE}"
