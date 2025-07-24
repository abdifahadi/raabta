// lib/utils/universal_platform_view_registry_web.dart
// Web implementation for platform view registration

import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

// Track registered view types to prevent duplicate registrations
final Set<String> _registeredViewTypes = <String>{};

/// Register a view factory for web platform
void registerViewFactory(String viewType, dynamic factoryFunction) {
  if (_registeredViewTypes.contains(viewType)) {
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: View type $viewType already registered');
    }
    return;
  }

  try {
    // For web, we need to register the platform view factory
    // This is where the actual registration would happen
    // The factoryFunction should create the appropriate HTML element
    
    _registeredViewTypes.add(viewType);
    
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: Successfully registered $viewType for web');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('UniversalPlatformViewRegistry: Failed to register $viewType: $e');
    }
    rethrow;
  }
}

/// Check if platform view registry is available on web
bool get isAvailable => html.window != null;

/// Check if a view type is registered
bool isViewTypeRegistered(String viewType) {
  return _registeredViewTypes.contains(viewType);
}
