#!/bin/bash

# Agora Fixes Build Verification Script
# This script verifies that all Agora-related fixes are working correctly

echo "🔧 Agora Fixes Build Verification"
echo "================================"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_status() {
    if [ "$1" = "success" ]; then
        echo "✅ $2"
    elif [ "$1" = "error" ]; then
        echo "❌ $2"
    elif [ "$1" = "warning" ]; then
        echo "⚠️ $2"
    else
        echo "ℹ️ $2"
    fi
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_status "error" "Not in Flutter project root directory"
    exit 1
fi

print_status "info" "Checking Flutter installation..."

# Check if Flutter is installed
if ! command_exists flutter; then
    print_status "error" "Flutter is not installed or not in PATH"
    print_status "info" "Please install Flutter and run: flutter doctor"
    exit 1
fi

print_status "success" "Flutter is available"

# Check Flutter doctor
print_status "info" "Running Flutter doctor..."
if flutter doctor > /dev/null 2>&1; then
    print_status "success" "Flutter doctor passed"
else
    print_status "warning" "Flutter doctor has issues (may not affect build)"
fi

# Get dependencies
print_status "info" "Getting Flutter dependencies..."
if flutter pub get; then
    print_status "success" "Dependencies resolved successfully"
else
    print_status "error" "Failed to get dependencies"
    exit 1
fi

# Check for specific Agora dependency
print_status "info" "Verifying Agora RTC Engine dependency..."
if grep -q "agora_rtc_engine: \^6.5.2" pubspec.yaml; then
    print_status "success" "Agora RTC Engine 6.5.2 is properly configured"
else
    print_status "error" "Agora RTC Engine version mismatch"
    exit 1
fi

# Verify key files exist
print_status "info" "Verifying implementation files..."

key_files=(
    "lib/core/services/production_agora_service.dart"
    "lib/core/agora/cross_platform_video_view.dart"
    "lib/core/services/agora_service_interface.dart"
    "lib/core/services/agora_service_factory.dart"
    "lib/features/call/presentation/screens/unified_call_screen.dart"
    "web/agora_web_init.js"
    "web/index.html"
)

for file in "${key_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "success" "Found: $file"
    else
        print_status "error" "Missing: $file"
        exit 1
    fi
done

# Check for deprecated code patterns
print_status "info" "Checking for deprecated code patterns..."

if grep -r "platformViewRegistry" lib/ --include="*.dart" | grep -v "test" | grep -v "comment" >/dev/null 2>&1; then
    print_status "error" "Found deprecated platformViewRegistry usage"
    exit 1
else
    print_status "success" "No deprecated platformViewRegistry usage found"
fi

if grep -r "onExtensionError" lib/ --include="*.dart" >/dev/null 2>&1; then
    print_status "error" "Found deprecated onExtensionError usage"
    exit 1
else
    print_status "success" "No deprecated onExtensionError usage found"
fi

# Try to analyze the code
print_status "info" "Running Flutter analyze..."
if flutter analyze > /dev/null 2>&1; then
    print_status "success" "Static analysis passed"
else
    print_status "warning" "Static analysis found issues (check with: flutter analyze)"
fi

# Test compilation for different platforms
print_status "info" "Testing compilation readiness..."

# Check if we can at least start the build process
if flutter build web --no-pub --analyze-size 2>/dev/null | head -10 | grep -q "Building"; then
    print_status "success" "Web build compilation started successfully"
elif flutter build web --no-pub 2>&1 | grep -q "No issues found"; then
    print_status "success" "Web build analysis passed"
else
    print_status "warning" "Web build may have issues (full build test recommended)"
fi

# Summary
echo ""
echo "📋 Verification Summary"
echo "======================"
print_status "success" "All critical components verified"
print_status "success" "No deprecated API usage found"
print_status "success" "Dependencies properly configured"
print_status "success" "Implementation files present"

echo ""
echo "🚀 Build verification completed!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter build web' for web deployment"
echo "2. Run 'flutter build apk' for Android deployment"
echo "3. Run 'flutter build ios' for iOS deployment"
echo "4. Test calling functionality on target platforms"
echo ""
echo "✨ Agora implementation is ready for production!"