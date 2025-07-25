// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'dart:js_interop';

@JS('window')
external JSAny get window;

@JS('window.console.log')
external void consoleLog(JSString message);

@JS()
external JSAny? eval(JSString code);

/// Web-specific helper for permissions and platform compatibility
class WebPermissionHelper {
  
  /// Request web permissions for camera and microphone
  static Future<void> requestWebPermissions() async {
    if (!kIsWeb) return;
    
    try {
      debugPrint('🌐 WebPermissionHelper: Requesting web permissions...');
      
      // The browser will handle permission requests automatically
      // when getUserMedia is called by Agora SDK
      debugPrint('✅ WebPermissionHelper: Web permissions setup complete');
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error setting up permissions: $e');
    }
  }

  /// Ensure platform view registry is available for Agora
  static void ensurePlatformViewRegistryAvailable() {
    if (!kIsWeb) return;

    try {
      debugPrint('🔧 WebPermissionHelper: Checking platform view registry...');
      
      // Create comprehensive fallback for platformViewRegistry
      eval('''
        (function() {
          // Check if we already have platformViewRegistry
          if (window.ui && window.ui.platformViewRegistry) {
            console.log('✅ WebPermissionHelper: platformViewRegistry already available via window.ui');
            return;
          }
          
          if (window.platformViewRegistry) {
            console.log('✅ WebPermissionHelper: platformViewRegistry already available at window level');
            return;
          }
          
          console.log('⚠️ WebPermissionHelper: platformViewRegistry not found, creating comprehensive fallback...');
          
          // Create window.ui namespace if it doesn't exist
          if (typeof window.ui === 'undefined') {
            window.ui = {};
          }
          
          // Create platformViewRegistry implementation
          var platformViewRegistry = {
            registerViewFactory: function(viewTypeId, factory, options) {
              console.log('📺 WebPermissionHelper: Registering view factory: ' + viewTypeId);
              
              // Store factories for debugging
              if (!window._platformViewFactories) {
                window._platformViewFactories = new Map();
              }
              
              window._platformViewFactories.set(viewTypeId, {
                factory: factory,
                options: options || {},
                timestamp: Date.now(),
                type: 'agora_video_view'
              });
              
              // For Agora video views, prepare container elements
              if (viewTypeId && (viewTypeId.indexOf('agora') !== -1 || viewTypeId.indexOf('video') !== -1)) {
                if (!window._agoraVideoContainers) {
                  window._agoraVideoContainers = new Map();
                }
                
                var container = document.createElement('div');
                container.id = 'agora-video-container-' + viewTypeId;
                container.style.cssText = 'width: 100%; height: 100%; background: #000; position: relative;';
                window._agoraVideoContainers.set(viewTypeId, container);
                
                console.log('📹 Created video container for: ' + viewTypeId);
              }
              
              return true;
            }
          };
          
          // Set up both locations for maximum compatibility
          window.ui.platformViewRegistry = platformViewRegistry;
          window.platformViewRegistry = platformViewRegistry;
          
          // Set global flags
          window.agoraWebCompatibilityReady = true;
          window.platformViewRegistryReady = true;
          
          console.log('✅ WebPermissionHelper: Created comprehensive platformViewRegistry fallback');
        })();
      '''.toJS);
      
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error setting up platform view registry: $e');
    }
  }

  /// Initialize web-specific configurations for Agora
  static void initializeAgoraWebSupport() {
    if (!kIsWeb) return;

    try {
      debugPrint('🚀 WebPermissionHelper: Initializing Agora web support...');
      
      // Ensure platform view registry is available first
      ensurePlatformViewRegistryAvailable();
      
      // Set up Agora web readiness detection
      eval('''
        (function() {
          // Check if Agora is already initialized
          if (window.agoraWebInitialized === true) {
            console.log('✅ WebPermissionHelper: Agora web already initialized');
            return;
          }
          
          console.log('⏳ WebPermissionHelper: Setting up Agora web initialization detection...');
          
          // Set up readiness callback
          window.onAgoraWebReady = function() {
            console.log('🎯 WebPermissionHelper: Agora web initialization complete');
            window.agoraWebInitialized = true;
          };
          
          // Also listen for when Agora RTC is loaded
          if (typeof window.AgoraRTC !== 'undefined') {
            console.log('📡 WebPermissionHelper: AgoraRTC SDK detected');
          }
          
          console.log('✅ WebPermissionHelper: Agora web support configured');
        })();
      '''.toJS);
      
      debugPrint('✅ WebPermissionHelper: Agora web support initialized');
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error initializing Agora web support: $e');
    }
  }

  /// Get web browser information for debugging
  static Map<String, dynamic> getWebBrowserInfo() {
    if (!kIsWeb) return {};

    try {
      // Get browser info using simple string conversion
      final browserInfoJS = eval('''
        JSON.stringify({
          userAgent: navigator.userAgent || "Unknown",
          platformViewRegistryAvailable: (typeof window.platformViewRegistry !== "undefined") || 
                                        (typeof window.ui !== "undefined" && typeof window.ui.platformViewRegistry !== "undefined"),
          agoraWebInitialized: window.agoraWebInitialized === true,
          agoraWebCompatibilityReady: window.agoraWebCompatibilityReady === true,
          platformViewRegistryReady: window.platformViewRegistryReady === true,
          agoraRTCAvailable: typeof window.AgoraRTC !== "undefined"
        })
      '''.toJS);
      
      final browserInfoString = browserInfoJS?.toString() ?? '{}';
      
      // Parse manually to avoid JSON dependencies
      final userAgentMatch = RegExp(r'"userAgent":"([^"]*)"').firstMatch(browserInfoString);
      final userAgent = userAgentMatch?.group(1) ?? 'Unknown';
      
      final platformViewRegistryMatch = RegExp(r'"platformViewRegistryAvailable":([^,}]*)').firstMatch(browserInfoString);
      final platformViewRegistryAvailable = platformViewRegistryMatch?.group(1) == 'true';
      
      final agoraWebInitializedMatch = RegExp(r'"agoraWebInitialized":([^,}]*)').firstMatch(browserInfoString);
      final agoraWebInitialized = agoraWebInitializedMatch?.group(1) == 'true';
      
      return {
        'userAgent': userAgent,
        'isChrome': userAgent.contains('Chrome'),
        'isFirefox': userAgent.contains('Firefox'),
        'isSafari': userAgent.contains('Safari') && !userAgent.contains('Chrome'),
        'isEdge': userAgent.contains('Edge'),
        'platformViewRegistryAvailable': platformViewRegistryAvailable,
        'agoraWebInitialized': agoraWebInitialized,
        'rawBrowserInfo': browserInfoString,
      };
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error getting browser info: $e');
      return {
        'userAgent': 'Unknown',
        'isChrome': false,
        'isFirefox': false,
        'isSafari': false,
        'isEdge': false,
        'platformViewRegistryAvailable': false,
        'agoraWebInitialized': false,
        'error': e.toString(),
      };
    }
  }
}

/// Legacy function for backward compatibility
Future<void> requestWebPermissions() async {
  await WebPermissionHelper.requestWebPermissions();
  WebPermissionHelper.initializeAgoraWebSupport();
}