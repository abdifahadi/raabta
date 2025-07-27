#!/bin/bash

# Flutter and Android SDK Environment Setup Script

# Set Android SDK environment variables
export ANDROID_HOME=/opt/android-sdk

# Add Flutter, Android SDK tools, and platform-tools to PATH
export PATH="$PATH:/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools"

# Set Java environment (optional, since Java 21 is already the default)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

echo "Flutter and Android environment variables set!"
echo "Android SDK location: $ANDROID_HOME"
echo "Flutter version: $(flutter --version | head -1)"
echo ""
echo "You can now run Flutter commands like:"
echo "  flutter doctor"
echo "  flutter build apk"
echo "  flutter run"