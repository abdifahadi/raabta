import 'package:flutter/foundation.dart' show kIsWeb;
import 'agora_service_interface.dart';
import 'agora_uikit_service.dart';
import 'agora_web_service.dart';

class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Get the appropriate AgoraService implementation based on platform
  /// Uses web-specific service for web platforms and UIKit for others
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    if (kIsWeb) {
      // Use web-specific service for better web compatibility
      _instance = AgoraWebService();
    } else {
      // Use AgoraUIKit service for native platforms (Android, iOS, Windows, macOS, Linux)
      _instance = AgoraUIKitService();
    }
    
    return _instance!;
  }
  
  /// Reset the instance (useful for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  /// Check if current platform supports Agora natively
  /// Now all platforms are supported through UIKit
  static bool get isNativeSupported => true;
  
  /// Check if current platform is web
  static bool get isWebPlatform => kIsWeb;
}