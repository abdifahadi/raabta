// lib/utils/universal_platform_view_registry_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

/// Web implementation for platform view registry
void registerViewFactory(String viewType, dynamic factoryFunction) {
  try {
    // Use platformViewRegistry from dart:ui_web for newer Flutter versions
    ui_web.platformViewRegistry.registerViewFactory(viewType, factoryFunction);
  } catch (e) {
    print('UniversalPlatformViewRegistry: Failed to register view factory $viewType: $e');
    // Continue execution even if registration fails
  }
}

/// Platform view registry availability - true for web platforms
bool get isAvailable => true;
