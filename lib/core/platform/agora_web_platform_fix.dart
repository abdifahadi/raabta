// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web-safe wrapper for Agora platform view operations
class AgoraWebPlatformFix {
  static bool _initialized = false;
  static final Map<String, html.Element Function(int)> _viewFactories = {};

  /// Initialize the web platform fix
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) return;

    try {
      _setupWebPlatformViews();
    } catch (e) {
      print('AgoraWebPlatformFix: Failed to initialize: $e');
    }
  }

  /// Register a view factory with safe platform view registry handling
  static void registerViewFactory(String viewType, html.Element Function(int) factory) {
    if (!kIsWeb) return;

    try {
      _viewFactories[viewType] = factory;
      
      // Use HTML-based fallback implementation for Web
      _registerWithHtmlFallback(viewType, factory);
    } catch (e) {
      print('AgoraWebPlatformFix: Failed to register view factory $viewType: $e');
      // Continue execution even if registration fails
    }
  }

  /// Register with HTML-based fallback method for Web
  static void _registerWithHtmlFallback(String viewType, html.Element Function(int) factory) {
    try {
      // Store the factory for manual creation when needed
      _viewFactories[viewType] = factory;
      print('AgoraWebPlatformFix: Using HTML fallback registration for $viewType');
    } catch (e) {
      print('AgoraWebPlatformFix: HTML fallback registration failed: $e');
    }
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
    if (!kIsWeb) return;
    
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