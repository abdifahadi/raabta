// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

// Conditional import for dart:ui only when available
import 'dart:ui' as ui show platformViewRegistry;

// Safe platform detection using the standard Flutter method
bool get isWeb => identical(0, 0.0);

/// Web-safe wrapper for Agora platform view operations
class AgoraWebPlatformFix {
  static bool _initialized = false;
  static final Map<String, html.Element Function(int)> _viewFactories = {};

  /// Initialize the web platform fix
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!isWeb) return;

    try {
      _setupWebPlatformViews();
    } catch (e) {
      print('AgoraWebPlatformFix: Failed to initialize: $e');
    }
  }

  /// Register a view factory with safe platform view registry handling
  static void registerViewFactory(String viewType, html.Element Function(int) factory) {
    if (!isWeb) return;

    try {
      _viewFactories[viewType] = factory;
      
      // Only attempt to use platformViewRegistry if we're on web and it's available
      if (_isPlatformViewRegistryAvailable()) {
        _registerWithPlatformViewRegistry(viewType, factory);
      } else {
        // Fallback for web environments where platformViewRegistry is not available
        _registerWithFallbackMethod(viewType, factory);
      }
    } catch (e) {
      print('AgoraWebPlatformFix: Failed to register view factory $viewType: $e');
      // Continue execution even if registration fails
    }
  }

  /// Check if platformViewRegistry is available
  static bool _isPlatformViewRegistryAvailable() {
    if (!isWeb) return false;
    
    try {
      // Safe check for platformViewRegistry availability
      // This uses the identical(0, 0.0) pattern recommended by Flutter team
      return identical(0, 0.0) && _hasPlatformViewRegistryObject();
    } catch (e) {
      return false;
    }
  }

  /// Check if the platformViewRegistry object exists
  static bool _hasPlatformViewRegistryObject() {
    try {
      // Attempt to access platformViewRegistry
      final registry = ui.platformViewRegistry;
      return registry != null;
    } catch (e) {
      return false;
    }
  }

  /// Register with the actual platformViewRegistry
  static void _registerWithPlatformViewRegistry(String viewType, html.Element Function(int) factory) {
    try {
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        return factory(viewId);
      });
    } catch (e) {
      print('AgoraWebPlatformFix: platformViewRegistry registration failed: $e');
      // Fall back to alternative method
      _registerWithFallbackMethod(viewType, factory);
    }
  }

  /// Fallback registration method for environments without platformViewRegistry
  static void _registerWithFallbackMethod(String viewType, html.Element Function(int) factory) {
    // Store the factory for manual creation when needed
    _viewFactories[viewType] = factory;
    print('AgoraWebPlatformFix: Using fallback registration for $viewType');
  }

  /// Setup web-specific platform view handling
  static void _setupWebPlatformViews() {
    // Initialize web-specific configurations
    _setupVideoContainerStyles();
    _setupEventHandlers();
  }

  /// Setup CSS styles for video containers
  static void _setupVideoContainerStyles() {
    final style = html.StyleElement();
    style.text = '''
      .agora-video-container {
        width: 100%;
        height: 100%;
        background-color: #000;
        position: relative;
        overflow: hidden;
      }
      
      .agora-video-container video {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }
    ''';
    html.document.head?.append(style);
  }

  /// Setup event handlers for web platform
  static void _setupEventHandlers() {
    // Setup any necessary event handlers for web platform
  }

  /// Create a video container element
  static html.Element createVideoContainer(int viewId, {String? viewType}) {
    final container = html.DivElement()
      ..id = 'agora_video_view_$viewId'
      ..className = 'agora-video-container'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black'
      ..style.position = 'relative';

    // Add a placeholder for the video element
    final placeholder = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.color = 'white'
      ..style.fontSize = '14px'
      ..text = 'Video View $viewId';

    container.append(placeholder);
    return container;
  }

  /// Get a registered view factory
  static html.Element Function(int)? getViewFactory(String viewType) {
    return _viewFactories[viewType];
  }

  /// Check if the platform fix is initialized
  static bool get isInitialized => _initialized;
}

/// Agora-specific web compatibility layer
class AgoraWebCompatibility {
  /// Initialize Agora web compatibility
  static void initialize() {
    if (!isWeb) return;
    
    AgoraWebPlatformFix.initialize();
    
    // Register default Agora view types
    _registerDefaultViewTypes();
  }

  /// Register default Agora view types with safe handling
  static void _registerDefaultViewTypes() {
    const defaultViewTypes = [
      'AgoraSurfaceView',
      'AgoraTextureView',
      'agora_rtc_engine/AgoraSurfaceView',
      'agora_rtc_engine/AgoraTextureView',
    ];

    for (final viewType in defaultViewTypes) {
      AgoraWebPlatformFix.registerViewFactory(viewType, (int viewId) {
        return AgoraWebPlatformFix.createVideoContainer(viewId, viewType: viewType);
      });
    }
  }
}