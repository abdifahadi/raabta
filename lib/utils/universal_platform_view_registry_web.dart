// lib/utils/universal_platform_view_registry_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Web implementation for platform view registry
/// This implementation provides safe access to platformViewRegistry on web platforms
void registerViewFactory(String viewType, dynamic factoryFunction) {
  try {
    // Use platformViewRegistry from dart:ui_web for Flutter web
    ui_web.platformViewRegistry.registerViewFactory(viewType, factoryFunction);
  } catch (e) {
    // Graceful degradation: log error and continue
    if (kDebugMode) debugPrint('UniversalPlatformViewRegistry: Failed to register view factory $viewType: $e');
    
    // For debugging: check if this is a common issue
    try {
      if (ui_web.platformViewRegistry.toString() == 'null') {
        if (kDebugMode) debugPrint('UniversalPlatformViewRegistry: platformViewRegistry is null');
      }
    } catch (checkError) {
      if (kDebugMode) debugPrint('UniversalPlatformViewRegistry: platformViewRegistry access error: $checkError');
    }
    
    // Continue execution even if registration fails to prevent app crash
  }
}

/// Platform view registry availability - true for web platforms where dart:ui_web is available
bool get isAvailable {
  try {
    // Test if platformViewRegistry is accessible
    return ui_web.platformViewRegistry.toString() != 'null';
  } catch (e) {
    // If we can't access it, consider it unavailable
    return false;
  }
}

/// Check if a specific view type is already registered
bool isViewTypeRegistered(String viewType) {
  try {
    // This is more of a placeholder since dart:ui_web doesn't provide
    // a direct way to check registered view types
    return true; // Assume available for web
  } catch (e) {
    return false;
  }
}
