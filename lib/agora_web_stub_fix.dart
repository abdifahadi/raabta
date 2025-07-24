// lib/agora_web_stub_fix.dart
// Modern Flutter Web Platform View Registry Fix for Agora RTC Engine
// This file provides a safe wrapper for the Agora RTC Engine web implementation
// that properly handles platformViewRegistry in the latest Flutter versions

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'utils/universal_platform_view_registry.dart';

/// Safe wrapper for Agora RTC Engine web platform view registration
/// This class provides compatibility with the latest Flutter web approach
class AgoraWebStubFix {
  
  /// Register a platform view factory safely for Agora components
  /// This method replaces direct ui.platformViewRegistry.registerViewFactory calls
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    if (!kIsWeb) {
      // On non-web platforms, this is handled by the platform-specific code
      if (kDebugMode) {
        print('AgoraWebStubFix: Skipping web platform view registration on non-web platform for $viewType');
      }
      return;
    }
    
    // Use our universal platform view registry for safe registration
    UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);
  }
  
  /// Attempt to register a platform view factory with error handling
  /// Returns true if successful, false otherwise
  static bool tryRegisterViewFactory(String viewType, dynamic factoryFunction) {
    if (!kIsWeb) {
      // On non-web platforms, assume success as it's handled differently
      return true;
    }
    
    return UniversalPlatformViewRegistry.tryRegisterViewFactory(viewType, factoryFunction);
  }
  
  /// Check if platform view registry is available
  static bool get isPlatformViewRegistryAvailable => 
      kIsWeb ? UniversalPlatformViewRegistry.isAvailable : true;
  
  /// Check if a specific view type is registered
  static bool isViewTypeRegistered(String viewType) {
    return UniversalPlatformViewRegistry.isViewTypeRegistered(viewType);
  }
  
  /// Modern replacement for ui.platformViewRegistry.registerViewFactory
  /// This is a drop-in replacement that can be used anywhere in the Agora codebase
  static void modernRegisterViewFactory(String viewType, dynamic factoryFunction) {
    try {
      if (kIsWeb) {
        // Import dart:ui_web dynamically to avoid compilation issues on non-web platforms
        registerViewFactory(viewType, factoryFunction);
        
        if (kDebugMode) {
          print('AgoraWebStubFix: Successfully registered modern view factory for $viewType');
        }
      } else {
        if (kDebugMode) {
          print('AgoraWebStubFix: Skipping web-specific view factory registration on native platform');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AgoraWebStubFix: Failed to register modern view factory for $viewType: $e');
      }
      // Continue execution to prevent app crashes
    }
  }
}

/// Legacy compatibility wrapper for older Agora code patterns
/// This provides a drop-in replacement for problematic platformViewRegistry usage
class LegacyPlatformViewRegistry {
  
  /// Drop-in replacement for ui.platformViewRegistry.registerViewFactory
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    AgoraWebStubFix.modernRegisterViewFactory(viewType, factoryFunction);
  }
}

/// Global function that can replace ui.platformViewRegistry calls
/// Usage: Replace `ui.platformViewRegistry.registerViewFactory` with `safePlatformViewRegistryRegisterViewFactory`
void safePlatformViewRegistryRegisterViewFactory(String viewType, dynamic factoryFunction) {
  AgoraWebStubFix.modernRegisterViewFactory(viewType, factoryFunction);
}
