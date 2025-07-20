# Raabta Calling System - Quick Setup Guide

## Prerequisites

1. **Flutter Environment**
   ```bash
   flutter --version  # Ensure Flutter is installed
   flutter doctor      # Check for any issues
   ```

2. **Dependencies Installation**
   ```bash
   flutter pub get
   ```

## Configuration Steps

### 1. Agora Configuration
The Agora credentials are already configured in `lib/core/config/agora_config.dart`:
- App ID: `4bfa94cebfb04852951bfdf9858dbc4b`
- Certificate: `8919043495b3435fba0ab1aa2973f29b`

### 2. Firebase Setup
Ensure your Firebase project is properly configured with:
- Authentication enabled
- Firestore database with proper rules
- User profiles collection

### 3. Platform Permissions

#### Android
Permissions are already added to `android/app/src/main/AndroidManifest.xml`:
- Camera access
- Microphone access
- Network state
- Bluetooth for audio routing

#### iOS
Permissions are already configured in `ios/Runner/Info.plist`:
- Camera usage description
- Microphone usage description

## Testing the Implementation

### 1. Build and Run
```bash
# For Android
flutter run

# For iOS (requires Mac and Xcode)
flutter run -d ios

# For Web
flutter run -d chrome
```

### 2. Test Flow

1. **Setup Two Test Accounts**
   - Create two user accounts in the app
   - Complete profile setup for both users

2. **Initiate a Call**
   - Login with first account
   - Go to user list (tap + icon in conversations)
   - Find the second user
   - Tap video call (📹) or audio call (📞) button

3. **Answer the Call**
   - On second device/account, incoming call screen should appear
   - Tap green button to answer or red to decline

4. **Test Call Features**
   - Mute/unmute microphone
   - Enable/disable video (for video calls)
   - Switch camera (front/back)
   - Toggle speaker
   - End call

### 3. Debug Information

Enable debug mode to see detailed logs:
```dart
// In main.dart, debug mode is already enabled
if (kDebugMode) {
  print('Debug logs will show call events');
}
```

Look for these log patterns:
- `📞` - Call service events
- `🔥` - Firebase operations
- `⚙️` - Service initialization

## Troubleshooting

### Common Issues

1. **"CallService not ready"**
   - Ensure services are properly initialized
   - Check ServiceLocator initialization

2. **"Permission denied"**
   - Grant camera and microphone permissions
   - Check platform-specific permission settings

3. **"Failed to join channel"**
   - Verify Agora App ID is correct
   - Check network connectivity
   - Ensure Firestore rules allow call document creation

4. **"User not found"**
   - Ensure both users have completed profile setup
   - Check Firestore user collection

### Network Requirements
- Stable internet connection
- Agora RTC requires specific ports (check Agora documentation)
- Firestore access for call state management

## File Locations

### Key Implementation Files
```
lib/
├── core/
│   ├── config/agora_config.dart          # Agora credentials
│   └── services/call_service.dart         # Main call service
├── features/call/
│   ├── domain/models/call_model.dart      # Call data model
│   ├── data/firebase_call_repository.dart # Firebase integration
│   └── presentation/screens/              # UI screens
└── features/chat/presentation/
    └── user_list_screen.dart              # Call buttons integration
```

### Modified Files
- `pubspec.yaml` - Added agora_rtc_engine dependency
- `lib/core/services/service_locator.dart` - Added call services
- `lib/features/auth/presentation/auth_wrapper.dart` - Added CallManager
- `android/app/src/main/AndroidManifest.xml` - Added permissions
- `lib/features/chat/presentation/user_list_screen.dart` - Added call buttons

## Next Steps

After successful testing:

1. **Phase 2 Implementation**
   - Implement secure token generation
   - Add Firebase Cloud Functions
   - Enable token-based authentication

2. **Additional Features**
   - Call history UI
   - Group calling
   - Push notifications for incoming calls
   - Call quality indicators

3. **Production Deployment**
   - Enable Agora token authentication
   - Configure production Firebase rules
   - Test on multiple devices and networks
   - Performance optimization

## Support

For issues or questions:
1. Check the debug logs first
2. Verify all prerequisites are met
3. Test with simple audio call before video
4. Ensure both test devices are on same network initially

**Happy Testing! 📞📹**