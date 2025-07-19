# 🧪 Raabta প্রজেক্ট টেস্টিং গাইড

## 🚀 প্রথমে রান করার জন্য প্রস্তুতি

### ১. Dependencies Install করুন
```bash
flutter pub get
```

### ২. Firebase Configuration চেক করুন
নিশ্চিত করুন যে এই ফাইলগুলো সঠিকভাবে আছে:
- `android/app/google-services.json` (Android এর জন্য)
- `ios/Runner/GoogleService-Info.plist` (iOS এর জন্য)
- `lib/firebase_options.dart` (সব platform এর জন্য)

## 📱 Android এ রান করার জন্য

### Android Device/Emulator চালু করুন
```bash
# Available devices দেখুন
flutter devices

# Android এ রান করুন
flutter run -d android
```

### Android Build করুন (যদি প্রয়োজন হয়)
```bash
flutter build apk --debug
```

## 🌐 Web এ রান করার জন্য

### Web সার্ভার চালু করুন
```bash
# Web এ রান করুন
flutter run -d chrome

# অথবা নির্দিষ্ট port এ
flutter run -d web-server --web-port 8080
```

### Web Build করুন
```bash
flutter build web
```

## 🖥️ Desktop এ রান করার জন্য

### Windows
```bash
flutter run -d windows
```

### macOS
```bash
flutter run -d macos
```

### Linux
```bash
flutter run -d linux
```

## 🔍 বিস্তারিত টেস্ট Plan

### ✅ Authentication Features টেস্ট করুন:
1. **Google Sign-in** - সফলভাবে লগইন হয় কিনা
2. **User Profile** - ইউজার তথ্য সঠিকভাবে লোড হয় কিনা
3. **Auto Login** - পরবর্তীতে automatically লগইন হয় কিনা

### ✅ Chat Features টেস্ট করুন:
1. **Text Messaging** - টেক্সট মেসেজ পাঠানো ও রিসিভ করা
2. **Real-time Updates** - মেসেজ তাৎক্ষণিক আপডেট হয় কিনা
3. **Message Status** - Sent, Delivered, Read status দেখা যায় কিনা

### ✅ Media Features টেস্ট করুন:

#### 📷 Image Messaging:
1. **Camera** থেকে ছবি তুলে পাঠানো
2. **Gallery** থেকে ছবি নির্বাচন করে পাঠানো
3. **Image Viewer** - ছবিতে tap করে full-screen দেখা
4. **Zoom & Pan** - ছবি zoom করা ও move করা

#### 🎬 Video Messaging:
1. **Video Selection** - গ্যালারি থেকে ভিডিও নির্বাচন
2. **Video Preview** - thumbnail দেখা যায় কিনা
3. **Video Player** - tap করে ভিডিও প্লে করা
4. **Player Controls** - play/pause, progress bar

#### 🎵 Audio Messaging:
1. **Audio File Selection** - অডিও ফাইল নির্বাচন
2. **Audio Player** - play/pause controls
3. **Progress Display** - সময় ও progress bar দেখা

#### 📄 Document Messaging:
1. **File Selection** - বিভিন্ন ধরনের ফাইল নির্বাচন
2. **File Info Display** - ফাইলের তথ্য (size, type) দেখা
3. **File Type Icons** - সঠিক আইকন দেখা যায় কিনা

### ✅ Chat Management টেস্ট করুন:
1. **Long Press Options** - মেসেজে long press করে options দেখা
2. **Chat Settings** - Settings screen open করা
3. **Mute/Unmute** - conversation mute করা
4. **Block/Unblock** - user block করা
5. **Clear History** - chat history clear করা

### ✅ Cross-Platform Compatibility:

#### 🌐 Web Platform:
- [ ] File picker কাজ করে কিনা
- [ ] Image/Video display সঠিক কিনা
- [ ] Responsive design ঠিক আছে কিনা
- [ ] Browser compatibility (Chrome, Firefox, Safari)

#### 📱 Mobile Platform:
- [ ] Camera access কাজ করে কিনা
- [ ] Gallery access সঠিক কিনা
- [ ] File system access ঠিক আছে কিনা
- [ ] Touch interactions smooth কিনা

#### 🖥️ Desktop Platform:
- [ ] File dialogs কাজ করে কিনা
- [ ] Window resizing responsive কিনা
- [ ] Keyboard shortcuts responsive কিনা

## ⚠️ সম্ভাব্য Issues ও Solutions:

### 1. Permission Issues (Android):
```
Error: Permission denied for camera/storage
```
**Solution**: App Settings এ গিয়ে permissions manually enable করুন

### 2. Firebase Connection Issues:
```
Error: Firebase configuration not found
```
**Solution**: Firebase configuration files সঠিকভাবে আছে কিনা চেক করুন

### 3. Web File Picker Issues:
```
Error: File picker not working on web
```
**Solution**: HTTPS এ serve করুন বা localhost ব্যবহার করুন

### 4. Build Issues:
```
Error: Gradle build failed (Android)
```
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### 5. iOS Simulator Issues:
```
Error: No iOS simulators available
```
**Solution**: Xcode install করুন ও simulator setup করুন

## 🏆 Expected Results:

### ✅ সফল হলে যা দেখবেন:
1. **Smooth UI** - সব UI elements properly load হবে
2. **Real-time Messaging** - Messages instantly appear হবে
3. **Media Upload/Display** - সব ধরনের media সঠিকভাবে কাজ করবে
4. **Cross-platform** - সব platform এ consistent behavior
5. **Error Handling** - যেকোনো error এর জন্য proper message

### 🎯 Performance Expectations:
- **App Launch**: 3-5 seconds এর মধ্যে
- **Message Send**: 1-2 seconds এর মধ্যে
- **Media Upload**: File size অনুযায়ী
- **Real-time Updates**: Instant (1 second এর কম)

## 📊 Debugging Commands:

### Flutter Logs দেখুন:
```bash
flutter logs
```

### Build Verbose Mode:
```bash
flutter run --verbose
```

### Clear Cache:
```bash
flutter clean
flutter pub get
```

### Check Doctor:
```bash
flutter doctor -v
```

## 🚨 Emergency Fixes:

যদি কোনো critical error আসে:

1. **Restart Flutter**:
```bash
flutter clean && flutter pub get && flutter run
```

2. **Reset Android**:
```bash
cd android && ./gradlew clean && cd .. && flutter run
```

3. **Check Dependencies**:
```bash
flutter pub deps
```

4. **Update Flutter**:
```bash
flutter upgrade
```

Happy Testing! 🎉