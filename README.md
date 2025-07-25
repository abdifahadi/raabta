# Raabta - Cross-Platform Chat App

A powerful cross-platform chat application built with Flutter, featuring real-time messaging, voice/video calling, and file sharing capabilities.

## 🎯 Key Features

- **Real-time Messaging**: Instant text messaging with read receipts
- **Voice & Video Calls**: High-quality calling powered by Agora UIKit
- **File Sharing**: Share images, videos, and documents seamlessly
- **Cross-Platform**: Works on Android, iOS, and Web
- **Firebase Integration**: Secure authentication and cloud storage
- **Modern UI**: Beautiful, responsive design with Material 3

## 🚀 Recent Updates

### ✅ Agora WebView PlatformViewRegistry Fix
- Fixed the `Undefined name 'platformViewRegistry'` error for Flutter web builds
- Added automated fix script: `./fix_agora_platformviewregistry.sh`
- Web platform now fully supports Agora video calling features
- See `AGORA_WEBVIEW_PLATFORMVIEWREGISTRY_FIX_COMPLETE.md` for details

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.24.3
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **Video Calling**: Agora UIKit
- **State Management**: Provider pattern
- **Database**: Cloud Firestore
- **Storage**: Firebase Cloud Storage

## 📱 Platform Support

- ✅ **Android**: Full functionality
- ✅ **iOS**: Full functionality  
- ✅ **Web**: Full functionality (including video calls)
- 🔄 **Desktop**: In development

## 🏗️ Setup Instructions

### Prerequisites
- Flutter SDK 3.24.3 or higher
- Firebase project setup
- Agora.io account for video calling

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/abdifahadi/raabta.git
   cd raabta
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Apply Agora Web Fix** (for web development)
   ```bash
   ./fix_agora_platformviewregistry.sh
   ```

4. **Configure Firebase**
   - Add your `google-services.json` (Android)
   - Add your `GoogleService-Info.plist` (iOS)
   - Update `lib/core/config/firebase_options.dart`

5. **Run the app**
   ```bash
   # For mobile
   flutter run
   
   # For web
   flutter run -d chrome
   ```

## 🌐 Web Development

For web development with video calling features:

1. Run the Agora fix script after any `flutter pub get`:
   ```bash
   ./fix_agora_platformviewregistry.sh
   ```

2. Build for web:
   ```bash
   flutter build web
   ```

3. Serve locally:
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```

## 🔧 Development Scripts

- `./fix_agora_platformviewregistry.sh` - Fix Agora web compatibility
- `./run_production_tests.sh` - Run comprehensive tests
- `./build_and_serve.sh` - Build and serve web version
- `./deploy_production_call_system.sh` - Deploy to production

## 📚 Documentation

- [Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md)
- [Agora WebView Fix](AGORA_WEBVIEW_PLATFORMVIEWREGISTRY_FIX_COMPLETE.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [Usage Guide](USAGE_GUIDE.md)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Apply necessary fixes (`./fix_agora_platformviewregistry.sh` for web changes)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Agora.io for video calling capabilities
- All contributors and testers

## 📞 Support

For support, email support@raabta.app or join our community Discord.

---

**Made with ❤️ by the Raabta Team**
