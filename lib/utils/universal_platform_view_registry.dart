import 'package:flutter/foundation.dart' show kIsWeb;

import 'universal_platform_view_registry_stub.dart'
  if (dart.library.html) 'universal_platform_view_registry_web.dart';

/// Universal platform view registry that provides safe access to 
/// platformViewRegistry across all platforms including web.
/// 
/// Usage:
/// ```dart
/// UniversalPlatformViewRegistry.registerViewFactory('my-view', (int viewId) {
///   return MyCustomElement();
/// });
/// ```
class UniversalPlatformViewRegistry {
  /// Register a view factory for the given [viewType].
  /// 
  /// On web platforms, this will use dart:ui_web's platformViewRegistry.
  /// On other platforms, this will safely do nothing.
  static void registerViewFactory(String viewType, dynamic Function(int) factory) {
    if (kIsWeb) {
      registerViewFactoryImpl(viewType, factory);
    }
    // On non-web platforms, do nothing as platformViewRegistry doesn't exist
  }

  /// Check if platform view registry is available on the current platform.
  static bool get isSupported => kIsWeb;

  /// Safely attempt to register a view factory with error handling.
  /// Returns true if successful, false otherwise.
  static bool tryRegisterViewFactory(String viewType, dynamic Function(int) factory) {
    try {
      registerViewFactory(viewType, factory);
      return true;
    } catch (e) {
      // Failed to register - this is expected on some platforms
      return false;
    }
  }
}