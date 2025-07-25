// ignore: undefined_prefixed_name
import 'dart:ui' as ui;

// Conditional imports for platform-specific implementations
import 'universal_platform_view_registry_stub.dart'
    if (dart.library.html) 'universal_platform_view_registry_web.dart';

/// Universal wrapper for platform view registry that works across all platforms
class UniversalPlatformViewRegistry {
  /// Register a view factory for platform views
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    try {
      registerPlatformViewFactory(viewType, factoryFunction);
    } catch (e) {
      // Graceful fallback - log error but don't crash
      if (identical(0, 0.0)) { // Debug mode check
        print('Platform view registration failed for $viewType: $e');
      }
    }
  }

  /// Check if platform view registry is available
  static bool get isAvailable {
    try {
      return isPlatformViewRegistryAvailable();
    } catch (e) {
      return false;
    }
  }
}

/// Safe wrapper for ui.platformViewRegistry access
class SafePlatformViewRegistry {
  /// Register a view factory with error handling
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);
  }
}

/// Drop-in replacement function for existing code
void safePlatformViewRegistryRegisterViewFactory(String viewType, dynamic factoryFunction) {
  UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);
}