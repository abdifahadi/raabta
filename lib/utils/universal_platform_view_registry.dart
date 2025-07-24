// lib/utils/universal_platform_view_registry.dart

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

// Conditional imports for platform-specific implementations
import 'universal_platform_view_registry_stub.dart'
    if (dart.library.js_util) 'universal_platform_view_registry_web.dart'
    as platform_registry;

/// Universal platform view registry that works across all platforms
/// 
/// This class provides a safe, cross-platform way to register platform views
/// without causing compilation errors on different platforms.
class UniversalPlatformViewRegistry {
  /// Register a view factory safely across all platforms
  /// 
  /// [viewType] - The unique identifier for the platform view
  /// [factoryFunction] - Function that creates the platform view
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    platform_registry.registerViewFactory(viewType, factoryFunction);
  }

  /// Check if platform view registry is available on the current platform
  static bool get isAvailable => platform_registry.isAvailable;
  
  /// Check if a specific view type is already registered
  /// 
  /// [viewType] - The view type to check
  /// Returns true if the view type is registered or registration is assumed to work
  static bool isViewTypeRegistered(String viewType) {
    return platform_registry.isViewTypeRegistered(viewType);
  }
  
  /// Safe registration that won't throw exceptions
  /// 
  /// [viewType] - The unique identifier for the platform view
  /// [factoryFunction] - Function that creates the platform view
  /// Returns true if registration was successful or assumed successful
  static bool tryRegisterViewFactory(String viewType, dynamic factoryFunction) {
    try {
      registerViewFactory(viewType, factoryFunction);
      return true;
    } catch (e) {
      // Log the error but don't crash the app
      if (kDebugMode) debugPrint('UniversalPlatformViewRegistry: Safe registration failed for $viewType: $e');
      return false;
    }
  }
}
