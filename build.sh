#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
SCHEME="Purrl"
CONFIGURATION="Release"
DERIVED_DATA_PATH="build"
APP_NAME="Purrl"
DMG_NAME="Purrl.dmg"
DMG_SOURCE_DIR="dmg-source"
ICNS_NAME="Purrl.icns"

# ---- 1. Clean previous artifacts ----
echo "==> Cleaning previous build artifacts..."
rm -rf "$DERIVED_DATA_PATH"
rm -rf "$DMG_SOURCE_DIR"
rm -f "$DMG_NAME"
rm -f rw.*."$DMG_NAME" 2>/dev/null || true
rm -f "$ICNS_NAME"

# ---- 2. Build in Release (universal: arm64 + x86_64) ----
echo "==> Building $APP_NAME (Release, universal binary)..."
xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Built app not found at $APP_PATH"
  exit 1
fi

# ---- 2b. Verify universal binary ----
echo "==> Verifying architectures..."
lipo -info "$APP_PATH/Contents/MacOS/$APP_NAME"

# ---- 3. Extract the .icns Xcode already generated from Assets.xcassets ----
echo "==> Extracting app icon (.icns) from the built app..."
FOUND_ICNS=$(find "$APP_PATH/Contents/Resources" -name "*.icns" | head -n 1)

if [ -z "$FOUND_ICNS" ]; then
  echo "WARNING: No .icns found inside the app bundle. The dmg/volume icon will be skipped."
else
  cp "$FOUND_ICNS" "$ICNS_NAME"
  echo "    -> Copied $(basename "$FOUND_ICNS") to $ICNS_NAME"
fi

# ---- 4. Prepare dmg-source ----
echo "==> Preparing dmg-source..."
mkdir -p "$DMG_SOURCE_DIR"
cp -R "$APP_PATH" "$DMG_SOURCE_DIR/"

# ---- 5. Create the dmg ----
echo "==> Creating $DMG_NAME..."
if [ -f "$ICNS_NAME" ]; then
  create-dmg \
    --volname "$APP_NAME" \
    --volicon "$ICNS_NAME" \
    --window-size 500 300 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 125 150 \
    --app-drop-link 375 150 \
    "$DMG_NAME" \
    "$DMG_SOURCE_DIR/"
else
  create-dmg \
    --volname "$APP_NAME" \
    --window-size 500 300 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 125 150 \
    --app-drop-link 375 150 \
    "$DMG_NAME" \
    "$DMG_SOURCE_DIR/"
fi

# ---- 6. Set the icon on the .dmg file itself (Finder icon) ----
if [ -f "$ICNS_NAME" ]; then
  echo "==> Setting Finder icon on $DMG_NAME..."
  if command -v fileicon >/dev/null 2>&1; then
    fileicon set "$DMG_NAME" "$ICNS_NAME"
  else
    echo "WARNING: 'fileicon' not found. Install it with: brew install fileicon"
  fi
fi

# ---- 7. Sign the update for Sparkle (if tools are present) ----
if [ -f "sparkle-tools/bin/sign_update" ]; then
  echo "==> Signing update for Sparkle..."
  ./sparkle-tools/bin/sign_update "$DMG_NAME"
fi

# ---- 8. Compute SHA256 ----
echo "==> Computing SHA256..."
SHA256=$(shasum -a 256 "$DMG_NAME" | awk '{print $1}')

echo ""
echo "======================================"
echo " Build complete: $DMG_NAME"
echo " SHA256: $SHA256"
echo "======================================"
echo ""
echo "Update your Homebrew cask with:"
echo "  version \"<new_version>\""
echo "  sha256 \"$SHA256\""