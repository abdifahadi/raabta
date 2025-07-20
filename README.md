# Raabta - Cross-Platform Chat Application

A modern, cross-platform chat application built with Flutter that supports real-time messaging, voice/video calls, and multimedia sharing across Android, Web, and Desktop platforms.

## Features

- 🔥 Real-time messaging with Firebase
- 📱 Cross-platform support (Android, Web, Desktop)
- 🎥 Voice and video calling
- 📸 Media sharing (images, videos, documents)
- 🔔 Push notifications
- 🔐 Secure authentication
- 🌙 Modern Material Design 3 UI

## Environment Setup

### Prerequisites

Before running this project, you need to set up your development environment for the platforms you want to target.

#### 1. Flutter SDK Installation

1. Download and install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Add Flutter to your PATH
3. Run `flutter doctor` to verify installation

#### 2. Android Development Setup

**Required for Android builds:**

1. **Install Android Studio:**
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK through Android Studio
   - Accept Android licenses: `flutter doctor --android-licenses`

2. **Set Android SDK Path:**
   ```bash
   # Add to your shell profile (.bashrc, .zshrc, etc.)
   export ANDROID_HOME=/path/to/your/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools
   ```

3. **Install Required SDK Components:**
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android SDK Tools
   - At least one Android SDK Platform (API level 21 or higher)

#### 3. Web Development Setup

**Required for Web builds:**

1. **Install Chrome or Chromium:**
   - Download from [google.com/chrome](https://www.google.com/chrome/)
   - Or install Chromium via package manager

2. **Set CHROME_EXECUTABLE (if needed):**
   ```bash
   # If Chrome is not in default location, set this environment variable
   export CHROME_EXECUTABLE=/path/to/your/chrome
   
   # Common paths:
   # macOS: /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
   # Linux: /usr/bin/google-chrome or /usr/bin/chromium-browser
   # Windows: C:\Program Files\Google\Chrome\Application\chrome.exe
   ```

3. **Enable Flutter Web:**
   ```bash
   flutter config --enable-web
   ```

#### 4. Desktop Development Setup (Linux)

**Required for Linux desktop builds:**

1. **Install Build Dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install ninja-build libgtk-3-dev
   ```

2. **Install Additional Dependencies:**
   ```bash
   sudo apt-get install \
     clang cmake ninja-build pkg-config libgtk-3-dev \
     liblzma-dev libstdc++-12-dev
   ```

3. **Enable Flutter Desktop:**
   ```bash
   flutter config --enable-linux-desktop
   ```

#### 5. Firebase Setup

1. **Create Firebase Project:**
   - Go to [console.firebase.google.com](https://console.firebase.google.com)
   - Create a new project
   - Enable Authentication, Firestore, and Storage

2. **Configure Firebase for Each Platform:**
   - **Android:** Download `google-services.json` and place in `android/app/`
   - **Web:** The web configuration is already included in the project
   - **iOS (future):** Download `GoogleService-Info.plist` for iOS support

### Quick Setup Commands

```bash
# 1. Clone the repository
git clone <repository-url>
cd raabta

# 2. Install dependencies
flutter pub get

# 3. Verify your setup
flutter doctor

# 4. Run on different platforms
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d linux           # Linux Desktop
```

## Running the Application

### Development Mode

```bash
# Web (Chrome required)
flutter run -d chrome

# Android (Android Studio/SDK required)
flutter run -d android

# Linux Desktop (ninja-build and libgtk-3-dev required)
flutter run -d linux
```

### Production Builds

```bash
# Web build
flutter build web --release

# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Linux Desktop
flutter build linux --release
```

## Troubleshooting

### Common Issues and Solutions

1. **"Chrome executable not found"**
   - Install Google Chrome or Chromium
   - Set `CHROME_EXECUTABLE` environment variable to Chrome path

2. **"Android SDK not found"**
   - Install Android Studio
   - Set `ANDROID_HOME` environment variable
   - Run `flutter doctor --android-licenses`

3. **"ninja not found" (Linux)**
   - Install ninja build tools: `sudo apt install ninja-build`

4. **"libgtk-3-dev not found" (Linux)**
   - Install GTK development libraries: `sudo apt install libgtk-3-dev`

5. **Firebase connection issues**
   - Verify Firebase configuration files are in correct locations
   - Check internet connectivity
   - Ensure Firebase project is properly configured

### Checking Your Environment

Run this command to verify your setup:

```bash
flutter doctor -v
```

This will show detailed information about your Flutter installation and any missing requirements.

## Project Structure

```
lib/
├── core/               # Core functionality and services
├── features/           # Feature-based modules
│   ├── auth/          # Authentication
│   ├── chat/          # Chat functionality
│   ├── call/          # Voice/Video calling
│   └── home/          # Home screen
└── main.dart          # App entry point
```

## Contributing

1. Ensure your environment is properly set up using the instructions above
2. Run `flutter analyze` to check for issues
3. Run `flutter test` to ensure tests pass
4. Follow the existing code structure and naming conventions

## License

This project is licensed under the MIT License - see the LICENSE file for details.
