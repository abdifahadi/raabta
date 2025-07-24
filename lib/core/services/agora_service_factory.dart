import 'package:flutter/foundation.dart' show kIsWeb;
import 'agora_service_interface.dart';
import 'agora_unified_service.dart';

class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Get the unified AgoraService implementation for all platforms
  /// Uses agora_uikit with cross-platform support for Web, Android, iOS, Windows, macOS, Linux
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    // Use unified service for all platforms with agora_uikit
    _instance = AgoraUnifiedService();
    
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