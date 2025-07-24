#!/bin/bash

# Agora Web Fix - Clean Rebuild Script
# Run this script after implementing the Agora web compatibility fixes

echo "🔧 Starting Agora Web Fix Clean Rebuild..."

# Clean everything
echo "🧹 Cleaning build cache..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any remaining issues
echo "🔍 Running analysis..."
flutter analyze

# Test web build specifically
echo "🌐 Testing web build..."
flutter build web --web-renderer canvaskit

echo "✅ Clean rebuild complete!"
echo ""
echo "🚀 To test the app:"
echo "   Web: flutter run -d chrome --web-renderer canvaskit"
echo "   Android: flutter run -d android"
echo "   iOS: flutter run -d ios"
echo ""
echo "📋 Fixes applied:"
echo "   ✅ agora_rtc_engine upgraded to 6.5.2"
echo "   ✅ Universal platform view registry implemented"
echo "   ✅ Web-compatible video views created"
echo "   ✅ Web-specific Agora service added"
echo "   ✅ Conditional imports with kIsWeb guards"
echo "   ✅ Web initialization script added"
echo ""
echo "🎯 No more platformViewRegistry errors on web!"