// lib/utils/universal_platform_view_registry_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Web implementation for platform view registry
/// This implementation provides safe access to platformViewRegistry on web platforms
/// Uses the modern Flutter web approach with dart:ui_web
void registerViewFactory(String viewType, dynamic factoryFunction) {
  try {
    // Use the modern platformViewRegistry from dart:ui_web for Flutter web
    // This is the correct way to register platform views in modern Flutter versions
    ui_web.platformViewRegistry.registerViewFactory(viewType, factoryFunction);
    
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: Successfully registered view factory for $viewType');
    }
  } catch (e) {
    // Graceful degradation: log error and continue
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: Failed to register view factory $viewType: $e');
    }
    
    // Additional debugging for common issues
    try {
      final registry = ui_web.platformViewRegistry;
      if (kDebugMode) {
        debugPrint('UniversalPlatformViewRegistry: platformViewRegistry available: ${registry != null}');
      }
    } catch (checkError) {
      if (kDebugMode) {
        debugPrint('UniversalPlatformViewRegistry: platformViewRegistry access error: $checkError');
      }
    }
    
    // Continue execution even if registration fails to prevent app crash
    // This ensures the app remains functional even if platform views can't be registered
  }
}

/// Platform view registry availability - true for web platforms where dart:ui_web is available
bool get isAvailable {
  try {
    // Test if platformViewRegistry is accessible in the current environment
    final registry = ui_web.platformViewRegistry;
    final isAccessible = registry.toString() != 'null';
    
    if (kDebugMode && !isAccessible) {
      debugPrint('UniversalPlatformViewRegistry: platformViewRegistry is null or inaccessible');
    }
    
    return isAccessible;
  } catch (e) {
    // If we can't access it, consider it unavailable
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: platformViewRegistry availability check failed: $e');
    }
    return false;
  }
}

/// Check if a specific view type is already registered
/// Note: dart:ui_web doesn't provide a direct way to check registered view types
/// This is more of a capability check for the web platform
bool isViewTypeRegistered(String viewType) {
  try {
    // Since dart:ui_web doesn't provide a way to check if a specific view type
    // is registered, we return the general availability of the platform view registry
    return isAvailable;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: isViewTypeRegistered check failed for $viewType: $e');
    }
    return false;
  }
}
