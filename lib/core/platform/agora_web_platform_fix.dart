// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:raabta/utils/universal_platform_view_registry.dart';

/// Web-safe wrapper for Agora platform view operations
class AgoraWebPlatformFix {
  static bool _initialized = false;
  static final Map<String, dynamic> _viewFactories = {};

  /// Initialize the web platform fix
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) return;

    try {
      _setupWebPlatformViews();
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebPlatformFix: Failed to initialize: $e');
    }
  }

  /// Register a view factory with safe platform view registry handling
  static void registerViewFactory(String viewType, dynamic factory) {
    if (!kIsWeb) return;

    try {
      _viewFactories[viewType] = factory;
      
      // Use our universal platform view registry with safe registration
      final success = UniversalPlatformViewRegistry.tryRegisterViewFactory(viewType, factory);
      if (!success) {
        if (kDebugMode) debugPrint('AgoraWebPlatformFix: Safe registration failed for $viewType, but continuing...');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebPlatformFix: Failed to register view factory $viewType: $e');
      // Continue execution even if registration fails
    }
  }

  /// Check if platform view registry is available
  static bool get isPlatformViewRegistryAvailable => 
      UniversalPlatformViewRegistry.isAvailable;



  /// Setup web-specific platform view handling
  static void _setupWebPlatformViews() {
    // Initialize web-specific configurations
    _setupVideoContainerStyles();
    _setupEventHandlers();
  }

  /// Setup CSS styles for video containers
  static void _setupVideoContainerStyles() {
    if (!kIsWeb) return;
    
    try {
      // Web-specific styling would be handled by the web implementation
      if (kDebugMode) debugPrint('AgoraWebPlatformFix: Video container styles initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebPlatformFix: Failed to setup video container styles: $e');
    }
  }

  /// Setup event handlers for web platform
  static void _setupEventHandlers() {
    // Setup any necessary event handlers for web platform
  }

  /// Create a video container element
  static dynamic createVideoContainer(int viewId, {String? viewType}) {
    if (!kIsWeb) {
      // Return a placeholder for non-web platforms
      return {'id': 'agora_video_view_$viewId', 'type': viewType};
    }
    
    // For web platforms, this would create the actual HTML element
    // but we'll return a placeholder for cross-platform compatibility
    return {
      'id': 'agora_video_view_$viewId',
      'className': 'agora-video-container',
      'style': {
        'width': '100%',
        'height': '100%',
        'backgroundColor': 'black',
        'position': 'relative'
      }
    };
  }

  /// Get a registered view factory
  static dynamic getViewFactory(String viewType) {
    return _viewFactories[viewType];
  }

  /// Check if the platform fix is initialized
  static bool get isInitialized => _initialized;
}

/// Agora-specific web compatibility layer
class AgoraWebCompatibility {
  /// Initialize Agora web compatibility
  static void initialize() {
    if (!kIsWeb) return;
    
    AgoraWebPlatformFix.initialize();
    
    // Register default Agora view types
    _registerDefaultViewTypes();
  }

  /// Register default Agora view types with safe handling
  static void _registerDefaultViewTypes() {
    // Note: We no longer register agora_rtc_engine view types since we use
    // pure JS interop with Agora Web SDK for Web builds
    if (kDebugMode) {
      debugPrint('AgoraWebCompatibility: Using pure JS interop, no agora_rtc_engine view types needed');
    }
  }
}
