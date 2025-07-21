import 'package:flutter/foundation.dart' show kIsWeb;
import 'agora_service_interface.dart';
import 'agora_service.dart';
import 'agora_service_web_stub.dart' if (dart.library.html) 'agora_service_web.dart';

class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Get the appropriate AgoraService implementation based on platform
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    if (kIsWeb) {
      _instance = AgoraServiceWeb();
    } else {
      _instance = AgoraService();
    }
    
    return _instance!;
  }
  
  /// Reset the instance (useful for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  /// Check if current platform supports Agora natively
  static bool get isNativeSupported => !kIsWeb;
  
  /// Check if current platform is web
  static bool get isWebPlatform => kIsWeb;
}