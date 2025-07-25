#!/bin/bash

# Raabta - Deprecation Warnings Fix Script
# This script fixes withOpacity deprecation warnings by replacing them with withValues

echo "🔧 Fixing Deprecation Warnings - withOpacity to withValues..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Find all Dart files with withOpacity usage
DART_FILES=$(find lib -name "*.dart" -type f)

echo "📁 Found $(echo "$DART_FILES" | wc -l) Dart files to process"

# Counter for fixes
FIXES_APPLIED=0

# Process each file
for file in $DART_FILES; do
    if grep -q "\.withOpacity(" "$file"; then
        echo "🔍 Processing: $file"
        
        # Create backup
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Use sed to replace withOpacity with withValues
        # This handles patterns like: Colors.red.withOpacity(0.5) -> Colors.red.withValues(alpha: 0.5)
        sed -i 's/\.withOpacity(\([^)]*\))/\.withValues(alpha: \1)/g' "$file"
        
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        echo "✅ Fixed: $file"
    fi
done

echo ""
echo "🎉 Deprecation warnings fix completed!"
echo "📊 Total files processed: $FIXES_APPLIED"
echo ""
echo "Summary of changes made:"
echo "  - Replaced .withOpacity(value) with .withValues(alpha: value)"
echo "  - Created backups for all modified files"
echo ""
echo "📝 You can now run:"
echo "  flutter analyze  # to verify warnings are fixed"
echo "  flutter build web  # to test compilation"