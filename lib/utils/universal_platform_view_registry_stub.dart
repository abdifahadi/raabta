// lib/utils/universal_platform_view_registry_stub.dart
// Stub implementation for non-web platforms

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Stub implementation for platforms that don't need platform view registration
/// This handles Android, iOS, Windows, macOS, Linux, etc.

/// Register a view factory (stub for non-web platforms)
void registerViewFactory(String viewType, dynamic factoryFunction) {
  // On non-web platforms, platform views are handled by the native plugin system
  // No registration needed here
  if (kDebugMode) {
    debugPrint('UniversalPlatformViewRegistry: Stub registration for $viewType on native platform');
  }
}

/// Check if platform view registry is available
/// For non-web platforms, this is always true since platform views are handled natively
bool get isAvailable => true;

/// Check if a view type is registered
/// For non-web platforms, assume it works since it's handled by the native system
bool isViewTypeRegistered(String viewType) {
  return true; // Assume success on native platforms
}
