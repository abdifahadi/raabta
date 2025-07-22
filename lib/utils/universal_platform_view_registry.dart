// lib/utils/universal_platform_view_registry.dart

// Conditional imports for platform-specific implementations
import 'universal_platform_view_registry_stub.dart'
    if (dart.library.html) 'universal_platform_view_registry_web.dart'
    as platform_registry;

/// Universal platform view registry that works across all platforms
class UniversalPlatformViewRegistry {
  /// Register a view factory safely across all platforms
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    platform_registry.registerViewFactory(viewType, factoryFunction);
  }

  /// Check if platform view registry is available
  static bool get isAvailable => platform_registry.isAvailable;
}
