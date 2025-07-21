import 'package:flutter/foundation.dart';

/// Web compatibility layer for Agora RTC Engine
/// This handles the platformViewRegistry issue on web platforms
class AgoraWebCompatibility {
  static bool get isWebSupported {
    // Check if we're on web and if Agora web support is available
    return kIsWeb;
  }

  static bool get canUseVideoCall {
    // For now, disable video calls on web due to compatibility issues
    // This can be enabled later when Agora web support is properly configured
    return !kIsWeb;
  }

  static String get platformMessage {
    if (kIsWeb) {
      return 'Video calling is currently not supported on web platform. Please use the mobile app for video calls.';
    }
    return 'Video calling is supported on this platform.';
  }

  /// Check if Agora services can be initialized
  static bool get canInitializeAgora {
    return !kIsWeb; // Disable Agora initialization on web for now
  }
}