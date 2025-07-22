# Agora Web Platform Usage Guide

## Overview
This implementation provides seamless video/audio calling across all platforms with automatic Web fallback.

## For Developers

### No Code Changes Required
The fix is completely transparent to existing code. All `CallService` methods work exactly the same:

```dart
// This works identically on all platforms now
final callService = CallService();
await callService.initialize();
await callService.joinCall(
  channelName: 'test-channel',
  token: 'your-token',
  uid: 12345,
  callType: CallType.video,
);
```

### Platform Detection is Automatic
```dart
// The factory automatically chooses the right implementation
if (kIsWeb) {
  // Uses AgoraWebService (pure JS interop)
} else {
  // Uses AgoraService (agora_rtc_engine)
}
```

## For Web Deployment

### Requirements
1. **HTTPS or Localhost**: Web calls require secure context
2. **Browser Permissions**: User must allow microphone/camera access
3. **Modern Browser**: Chrome, Firefox, Safari, Edge (recent versions)

### Included Automatically
- Agora Web SDK is loaded from CDN in `web/index.html`
- Debug mode enabled for localhost development
- Proper error handling and logging

## Build Instructions

### Web Build
```bash
flutter build web
# No more platformViewRegistry errors!
```

### Native Builds
```bash
flutter build apk    # Android
flutter build ios    # iOS  
flutter build macos  # macOS
flutter build windows # Windows
# All work exactly as before
```

## Testing Checklist

### Web Testing
- [ ] Build completes without errors
- [ ] No console errors about platformViewRegistry
- [ ] Camera/microphone permissions work
- [ ] Video calls connect successfully
- [ ] Audio calls work properly
- [ ] Mute/unmute functions correctly
- [ ] Video on/off works
- [ ] Multiple users can join

### Native Testing  
- [ ] Existing functionality unchanged
- [ ] Video views render correctly
- [ ] All call controls work
- [ ] No build regressions

## Troubleshooting

### Web Issues
- **Permission denied**: Ensure HTTPS or localhost
- **SDK not loaded**: Check browser console for script errors
- **No video**: Verify camera permissions granted

### Build Issues
- **Missing dependencies**: Run `flutter pub get`
- **Import errors**: Check conditional imports are correct

## Architecture Benefits

### Separation of Concerns
- Web: Pure JavaScript interop (fast, compatible)
- Native: Full native SDK (feature-complete)

### No Compromises
- Web gets optimized Web implementation
- Native platforms get full native features
- Same API surface for developers

### Future-Proof
- Easy to update Web SDK independently
- Native SDK updates don't affect Web
- Can optimize each platform separately
