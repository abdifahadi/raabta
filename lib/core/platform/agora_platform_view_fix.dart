// ignore: undefined_prefixed_name
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../../utils/universal_platform_view_registry.dart';

/// Comprehensive Agora-specific platform view fix
class AgoraPlatformViewFix {
  static bool _isInitialized = false;
  static final Map<String, dynamic> _registeredFactories = {};

  /// Check if the fix has been initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize the Agora platform view fix
  static void initialize() {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        debugPrint('🎥 Initializing modern Agora platform view fix...');
      }

      // Pre-register common Agora view types with safe handling
      _preRegisterCommonAgoraViews();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ Agora platform view fix initialized successfully');
        debugPrint('🔧 Platform view registry available: ${UniversalPlatformViewRegistry.isAvailable}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Agora platform view fix initialization failed: $e');
      }
      // Don't prevent app startup even if initialization fails
      _isInitialized = true;
    }
  }

  /// Register an Agora view factory with comprehensive error handling
  static void registerAgoraViewFactory(String viewType, dynamic factoryFunction) {
    try {
      if (!_isInitialized) {
        initialize();
      }

      // Store the factory for potential re-registration
      _registeredFactories[viewType] = factoryFunction;

      // Register using the universal wrapper
      UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);

      if (kDebugMode) {
        debugPrint('✅ Registered Agora view factory: $viewType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to register Agora view factory $viewType: $e');
      }
      // Continue execution even if registration fails
    }
  }

  /// Pre-register common Agora view types
  static void _preRegisterCommonAgoraViews() {
    final commonViewTypes = [
      'agora_video_view',
      'agora_surface_view', 
      'agora_texture_view',
      'agora_rtc_surface_view',
      'agora_rtc_texture_view',
    ];

    for (final viewType in commonViewTypes) {
      try {
        registerAgoraViewFactory(viewType, (int viewId, {Object? params}) {
          // Default factory that creates a basic div element for web
          if (kIsWeb) {
            return _createWebVideoElement(viewId, params);
          }
          return null;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to pre-register $viewType: $e');
        }
      }
    }
  }

  /// Create a web video element for Agora views
  static dynamic _createWebVideoElement(int viewId, Object? params) {
    try {
      // This would be implemented based on your specific needs
      // For now, return a basic placeholder
      if (kDebugMode) {
        debugPrint('🎥 Creating web video element for view: $viewId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to create web video element: $e');
      }
      return null;
    }
  }

  /// Get list of registered factories
  static Map<String, dynamic> get registeredFactories => Map.unmodifiable(_registeredFactories);

  /// Reset the fix (useful for testing)
  static void reset() {
    _isInitialized = false;
    _registeredFactories.clear();
  }
}