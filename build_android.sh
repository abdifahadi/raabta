#!/bin/bash

# Android Build Script for Raabta App
# This script sets up the environment and builds the Android APK

echo "🚀 Setting up Android build environment..."

# Set up environment variables
export PATH="/tmp/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

echo "✅ Environment variables set:"
echo "  FLUTTER_PATH: /tmp/flutter/bin"
echo "  ANDROID_HOME: $ANDROID_HOME"
echo "  JAVA_HOME: $JAVA_HOME"

# Check Flutter installation
echo "🔍 Checking Flutter installation..."
flutter --version

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build the APK
echo "🔨 Building Android APK (Debug)..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "To run on device/emulator:"
    echo "  flutter run"
    echo ""
    echo "To install APK manually:"
    echo "  adb install build/app/outputs/flutter-apk/app-debug.apk"
else
    echo "❌ Build failed!"
    echo "Check the error messages above for details."
    exit 1
fi