# Call Functionality Test Guide

## ✅ Features Implemented

### 1. 🔔 Incoming Call Listening
- [x] App listens to Firestore "calls" collection on startup/login
- [x] Filters calls where `receiverId == currentUser.uid` and `status == "ringing"`
- [x] CallManager widget integrated in AuthWrapper

### 2. 📞 Incoming Call Screen
- [x] Shows caller info (name, photo, call type)
- [x] Accept/Decline buttons with animations
- [x] Auto-plays ringtone sound
- [x] 30-second timeout with auto-decline
- [x] Proper cleanup on dispose

### 3. ✅ Accept Call Flow
- [x] Updates Firestore `call.status = "accepted"`
- [x] Navigates to CallScreen
- [x] Joins the same Agora channel
- [x] Stops ringtone and timeout

### 4. ❌ Decline Call Flow
- [x] Updates Firestore `call.status = "declined"`
- [x] Stops ringtone and closes UI
- [x] Handles timeout scenario

### 5. 🔁 Call Status Sync
- [x] Both caller and receiver listen for status updates
- [x] Caller sees "Call Declined" message when rejected
- [x] Real-time status synchronization via Firestore streams

### 6. 🧪 Cross-Platform Support
- [x] **Android**: Native ringtone via MediaPlayer
- [x] **iOS**: Native ringtone via AVAudioPlayer
- [x] **Web**: HTML5 Audio API (registerWebView implemented)
- [x] **macOS**: Native sound via AVAudioPlayer/NSSound
- [x] **Windows**: System sounds via PlaySound API

### 7. 🔒 Firestore Security Rules
- [x] Added `calls/{callId}` collection rules
- [x] Only caller and receiver can read/write call data
- [x] Proper permissions for create/update/delete operations

## 🧪 Testing Instructions

### Test 1: Basic Incoming Call
1. **Setup**: Two devices/browsers with different users logged in
2. **Action**: User A calls User B (video or audio)
3. **Expected**: 
   - User B sees incoming call screen immediately
   - Ringtone starts playing
   - Caller info displays correctly
   - Accept/Decline buttons work

### Test 2: Accept Call
1. **Setup**: Incoming call on User B's device
2. **Action**: User B clicks Accept
3. **Expected**:
   - Ringtone stops
   - Navigates to CallScreen
   - Both users join the same channel
   - Video/audio works properly

### Test 3: Decline Call
1. **Setup**: Incoming call on User B's device
2. **Action**: User B clicks Decline
3. **Expected**:
   - Ringtone stops
   - Call screen closes
   - User A sees "Call Declined" message
   - Call ends properly

### Test 4: Call Timeout
1. **Setup**: Incoming call on User B's device
2. **Action**: Wait 30 seconds without responding
3. **Expected**:
   - Ringtone stops automatically
   - Call auto-declines
   - "Call timed out" message shows
   - User A sees call ended

### Test 5: Platform-Specific Ringtones
1. **Android**: Should play default system ringtone
2. **iOS**: Should play system ringtone or vibrate
3. **Web**: Should play web audio (may be limited by browser)
4. **Desktop**: Should play system sound/beep

### Test 6: Multiple Calls
1. **Setup**: User receives multiple calls
2. **Expected**: Only shows one incoming call at a time
3. **Edge case**: Handle rapid call creation/cancellation

## 🔧 Technical Implementation Details

### Architecture
```
AuthWrapper
└── CallManager (listens for incoming calls)
    ├── IncomingCallScreen (with ringtone + timeout)
    ├── CallScreen (for active calls)
    └── RingtoneService (cross-platform sound)
```

### Key Services
- **CallManager**: Manages call state and navigation
- **RingtoneService**: Handles platform-specific ringtones
- **FirebaseCallRepository**: Firestore integration for calls
- **CallService**: High-level call management

### Firestore Structure
```
calls/{callId}
├── callerId: string
├── receiverId: string
├── status: "ringing" | "accepted" | "declined" | "ended"
├── callType: "audio" | "video"
├── channelName: string
├── createdAt: timestamp
├── callerName: string
├── callerPhotoUrl: string
├── receiverName: string
└── receiverPhotoUrl: string
```

## 🚀 Deployment Steps

1. **Deploy Firestore Rules**:
   ```bash
   ./deploy_firestore_rules.sh
   ```

2. **Build and Test**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug  # Android
   flutter build ios --debug  # iOS
   flutter build web          # Web
   ```

3. **Test on Multiple Platforms**:
   - Android device/emulator
   - iOS device/simulator
   - Web browser (Chrome/Safari)
   - Desktop (Windows/macOS/Linux)

## ⚠️ Known Limitations

1. **Web Audio**: Browser may block audio without user interaction
2. **iOS Permissions**: May need microphone/camera permissions for ringtone
3. **Background Calls**: Limited by platform background restrictions
4. **Network**: Requires stable internet for real-time sync

## 🔄 Future Enhancements

1. **Push Notifications**: For incoming calls when app is closed
2. **Custom Ringtones**: Allow users to select custom ringtone files
3. **Call History**: Show missed/declined calls in history
4. **Group Calls**: Support for multi-participant calls
5. **Call Recording**: Record calls with user consent

## ✅ Verification Checklist

- [ ] Incoming calls show immediately
- [ ] Ringtone plays on all platforms
- [ ] Accept/decline buttons work
- [ ] 30-second timeout works
- [ ] Call status syncs between users
- [ ] Navigation flows work correctly
- [ ] Firestore rules deployed
- [ ] Cross-platform compatibility verified
- [ ] No memory leaks or crashes
- [ ] Proper error handling