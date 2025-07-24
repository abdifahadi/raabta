# Agora Web Call Migration Guide

## Overview

This document outlines the migration from `agora_rtc_engine` to `agora_uikit` to fix web call issues and provide better cross-platform support.

## Issues Fixed

### 1. Platform View Registry Issues
- **Problem**: `agora_rtc_engine` 6.3.2 had issues with `platformViewRegistry` being deprecated in Flutter web
- **Solution**: Migrated to `agora_uikit` which handles platform-specific implementation internally

### 2. Web Support Limitations  
- **Problem**: `agora_rtc_engine` had limited web support (alpha stage) with many features not implemented
- **Solution**: `agora_uikit` provides full web support with proper video rendering

### 3. Complex Custom Implementation
- **Problem**: Multiple custom workarounds and platform-specific patches were needed
- **Solution**: `agora_uikit` provides a unified API across all platforms

## Changes Made

### Dependencies Updated
```yaml
# Before
agora_rtc_engine: ^6.3.2

# After  
agora_uikit: ^1.3.10
```

### Files Added
- `lib/core/services/agora_uikit_service.dart` - New cross-platform service implementation
- `lib/features/call/presentation/screens/agora_uikit_call_screen.dart` - New call screen using UIKit components

### Files Removed
- `lib/core/services/agora_service.dart` - Old native implementation
- `lib/core/services/improved_agora_web_service.dart` - Old web implementation  
- `lib/core/services/agora_web_service.dart` - Old web service
- `lib/core/platform/agora_platform_view_fix.dart` - Platform view workarounds
- `lib/core/platform/agora_web_platform_fix.dart` - Web platform workarounds
- `lib/utils/universal_platform_view_registry*.dart` - Custom platform view registry
- `lib/core/utils/web_view_*.dart` - Custom web view utilities

### Service Factory Updated
```dart
// Before: Platform-specific implementations
if (kIsWeb) {
  _instance = ImprovedAgoraWebService();
} else {
  _instance = AgoraService();
}

// After: Single implementation for all platforms
_instance = AgoraUIKitService();
```

### Web Configuration Simplified
```html
<!-- Before: Manual Agora Web SDK loading -->
<script src="https://download.agora.io/sdk/release/AgoraRTC_N.js"></script>
<!-- Complex initialization scripts -->

<!-- After: Automatic handling -->
<!-- Agora UIKit handles Web SDK loading automatically -->
```

## Platform Support

### ✅ Supported Platforms
- **Web** - Full support with video/audio calling
- **Android** - Native Agora SDK through UIKit
- **iOS** - Native Agora SDK through UIKit  
- **Windows** - Native Agora SDK through UIKit
- **macOS** - Native Agora SDK through UIKit
- **Linux** - Native Agora SDK through UIKit

### Key Features
- ✅ Video calling
- ✅ Audio calling  
- ✅ Mute/unmute
- ✅ Video enable/disable
- ✅ Camera switching (mobile/desktop)
- ✅ Permission handling
- ✅ Cross-platform video rendering
- ✅ Token-based authentication

## API Changes

### Service Interface
The `AgoraServiceInterface` remains the same, ensuring backward compatibility:

```dart
// No changes needed in existing code
final agoraService = ServiceLocator().agoraService;
await agoraService.initialize();
await agoraService.joinCall(
  channelName: channelName,
  callType: CallType.video,
);
```

### Video Views
```dart
// Before: Platform-specific video views
AgoraVideoView(
  controller: VideoViewController(
    rtcEngine: _engine,
    canvas: VideoCanvas(uid: 0),
  ),
)

// After: UIKit-based video views (automatic platform handling)
AgoraVideoViewer(
  client: _client,
  layoutType: Layout.floating,
)
```

## Usage Example

### Basic Call Setup
```dart
import 'package:agora_uikit/agora_uikit.dart';

class CallScreen extends StatefulWidget {
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  AgoraClient? client;
  
  @override
  void initState() {
    super.initState();
    initAgora();
  }
  
  void initAgora() async {
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: "your-app-id",
        channelName: "test",
      ),
    );
    await client!.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AgoraVideoViewer(client: client!),
          AgoraVideoButtons(client: client!),
        ],
      ),
    );
  }
}
```

## Migration Steps

### 1. Update Dependencies
```bash
flutter pub remove agora_rtc_engine
flutter pub add agora_uikit
```

### 2. Update Service Implementation
- Replace `AgoraService` with `AgoraUIKitService`
- Update `AgoraServiceFactory` to use UIKit service

### 3. Update Call Screens
- Replace custom video views with `AgoraVideoViewer`
- Remove platform-specific workarounds
- Use `AgoraVideoButtons` for call controls

### 4. Clean Web Configuration
- Remove manual Agora Web SDK script tags
- Remove custom video containers
- Let UIKit handle everything automatically

### 5. Test All Platforms
- Web: Test in Chrome, Firefox, Safari
- Mobile: Test on Android and iOS devices
- Desktop: Test on Windows, macOS, Linux

## Browser Compatibility

### Web Support
- ✅ Chrome 58+
- ✅ Firefox 56+
- ✅ Safari 11+
- ✅ Edge 79+

### Required Permissions
- Camera access for video calls
- Microphone access for audio
- Handled automatically by browser prompts

## Performance Improvements

### Before (agora_rtc_engine)
- Complex platform-specific code paths
- Manual video rendering setup
- Custom permission handling
- Web limitations and compatibility issues

### After (agora_uikit)
- Unified codebase across platforms
- Automatic video rendering optimization
- Built-in permission management
- Full web platform support

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure browser allows camera/microphone access
   - Check that HTTPS is used in production

2. **Video Not Rendering**
   - UIKit handles this automatically
   - Ensure proper initialization of AgoraClient

3. **Build Errors**
   - Clean build: `flutter clean && flutter pub get`
   - Ensure all old Agora files are removed

### Debug Tips
- Enable debug logs: `AgoraClient` shows detailed logs
- Check browser console for web-specific issues
- Use `kDebugMode` prints in development

## Production Deployment

### Web Deployment
1. Build for web: `flutter build web`
2. Ensure HTTPS is configured
3. Test camera/microphone permissions
4. Verify token generation works

### Mobile Deployment
1. Update permissions in platform-specific config
2. Test on real devices (not just simulators)
3. Verify token service integration

## Benefits

### Developer Experience
- ✅ Single API for all platforms
- ✅ Less boilerplate code
- ✅ Automatic platform optimization
- ✅ Better error handling

### End User Experience  
- ✅ Consistent UI across platforms
- ✅ Better web performance
- ✅ Automatic permission handling
- ✅ Improved video quality

### Maintenance
- ✅ Fewer platform-specific issues
- ✅ Official Agora support
- ✅ Regular updates from Agora team
- ✅ Reduced custom workarounds