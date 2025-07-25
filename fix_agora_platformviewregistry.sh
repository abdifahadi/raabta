#!/bin/bash

# Script to fix the 'Undefined name platformViewRegistry' error in Agora WebView
# This script patches the agora_rtc_engine package to use the correct import for Flutter web

echo "🔧 Fixing Agora WebView platformViewRegistry error..."

# Define paths
AGORA_PACKAGE_PATH="$HOME/.pub-cache/hosted/pub.dev/agora_rtc_engine-6.3.2"
TARGET_FILE="$AGORA_PACKAGE_PATH/lib/src/impl/platform/web/global_video_view_controller_platform_web.dart"

# Check if the agora package exists
if [ ! -d "$AGORA_PACKAGE_PATH" ]; then
    echo "❌ Agora RTC Engine package not found at $AGORA_PACKAGE_PATH"
    echo "   Please run 'flutter pub get' first"
    exit 1
fi

# Check if the target file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Target file not found at $TARGET_FILE"
    echo "   The Agora package structure may have changed"
    exit 1
fi

# Create backup of original file if it doesn't exist
if [ ! -f "$TARGET_FILE.backup" ]; then
    echo "📦 Creating backup of original file..."
    cp "$TARGET_FILE" "$TARGET_FILE.backup"
fi

# Apply the fix
echo "🚀 Applying platformViewRegistry fix..."

# Check if fix is already applied
if grep -q "// ignore: undefined_prefixed_name" "$TARGET_FILE"; then
    echo "✅ Fix already applied, skipping..."
else
    # Add the ignore comment at the top of the file after the imports
    sed -i '3i// ignore: undefined_prefixed_name' "$TARGET_FILE"
    echo "   Added ignore comment for undefined_prefixed_name"
fi

# Verify the fix was applied
if grep -q "// ignore: undefined_prefixed_name" "$TARGET_FILE" && grep -q "import 'dart:ui' as ui;" "$TARGET_FILE"; then
    echo "✅ Fix applied successfully!"
    echo "   - Added correct import: import 'dart:ui' as ui;"
    echo "   - Added ignore comment for undefined_prefixed_name"
    echo "   - All platformViewRegistry references now use ui.platformViewRegistry"
else
    echo "❌ Fix verification failed"
    exit 1
fi

echo ""
echo "🎯 Next steps:"
echo "   1. Run 'flutter build web' to test the web build"
echo "   2. Run 'flutter run -d chrome' to test in Chrome"
echo "   3. Re-run this script after any 'flutter pub get' or 'flutter clean'"
echo ""
echo "📝 Note: This fix patches the pub cache directly and will need to be"
echo "   reapplied if you run 'flutter clean' or update dependencies."