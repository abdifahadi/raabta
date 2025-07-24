import 'package:flutter/foundation.dart' show kIsWeb;
import 'agora_service_interface.dart';
import 'agora_uikit_service.dart';

class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Get the appropriate AgoraService implementation based on platform
  /// Now uses AgoraUIKit for all platforms including web
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    // Use AgoraUIKit service for all platforms (Web, Android, iOS, Windows, macOS, Linux)
    _instance = AgoraUIKitService();
    
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