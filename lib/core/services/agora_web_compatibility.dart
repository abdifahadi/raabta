import 'package:flutter/foundation.dart';

/// Web compatibility layer for Agora RTC Engine
/// This handles cross-platform support for Agora RTC Engine
class AgoraWebCompatibility {
  static bool get isWebSupported {
    // Web is now fully supported with Agora Web SDK
    return kIsWeb;
  }

  static bool get canUseVideoCall {
    // Video calls are now supported on all platforms including web
    return true;
  }

  static String get platformMessage {
    if (kIsWeb) {
      return 'Web calling is supported with Agora Web SDK.';
    }
    return 'Native calling is supported with Agora RTC Engine.';
  }

  /// Check if Agora services can be initialized
  static bool get canInitializeAgora {
    // Agora is now supported on all platforms
    return true;
  }

  /// Get platform-specific engine creation method
  static bool get useWebEngine {
    return kIsWeb;
  }
}