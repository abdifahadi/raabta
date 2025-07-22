// lib/utils/universal_platform_view_registry_stub.dart

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Stub implementation for non-web platforms
/// On native platforms, platform views are handled through the Flutter framework
void registerViewFactory(String viewType, dynamic factoryFunction) {
  if (kIsWeb) {
    // For web platforms that somehow use this stub, do nothing
    return;
  }
  
  // On native platforms, platform view registration is typically handled
  // through the plugin system and Flutter framework, not directly through dart:ui
  if (kDebugMode) {
    print('UniversalPlatformViewRegistry: Native platform view registration for $viewType (handled by framework)');
  }
  
  // Note: On native platforms (Android, iOS, etc.), platform views are registered
  // through the platform-specific plugin code, not through Dart code.
  // This is expected behavior.
}

/// Platform view registry availability
bool get isAvailable {
  if (kIsWeb) {
    return false; // Web should use the web implementation
  }
  
  // On native platforms, platform views are available through the framework
  // but not through dart:ui platformViewRegistry
  return true; // Framework handles platform views on native platforms
}

/// Check if a specific view type is already registered (stub implementation)
bool isViewTypeRegistered(String viewType) {
  if (kIsWeb) {
    return false; // Web should use the web implementation
  }
  
  // On native platforms, assume view types can be registered through the framework
  return true; // Framework handles platform view registration
}
