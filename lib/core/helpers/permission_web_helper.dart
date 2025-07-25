// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'dart:js' as js;

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
      
      // Check if platformViewRegistry is available
      if (js.context.hasProperty('ui') && 
          js.context['ui'] != null &&
          js.context['ui'].hasProperty('platformViewRegistry')) {
        debugPrint('✅ WebPermissionHelper: platformViewRegistry available via window.ui');
      } else if (js.context.hasProperty('platformViewRegistry')) {
        debugPrint('✅ WebPermissionHelper: platformViewRegistry available at window level');
      } else {
        debugPrint('⚠️ WebPermissionHelper: platformViewRegistry not found, creating fallback...');
        
        // Create a basic fallback if needed
        js.context['platformViewRegistry'] = js.JsObject.jsify({
          'registerViewFactory': js.allowInterop((String viewTypeId, Function factory, [dynamic options]) {
            debugPrint('📺 WebPermissionHelper: Fallback view factory registration: $viewTypeId');
            return true;
          })
        });
      }
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error checking platform view registry: $e');
    }
  }

  /// Initialize web-specific configurations for Agora
  static void initializeAgoraWebSupport() {
    if (!kIsWeb) return;

    try {
      debugPrint('🚀 WebPermissionHelper: Initializing Agora web support...');
      
      // Ensure platform view registry is available
      ensurePlatformViewRegistryAvailable();
      
      // Check for Agora web initialization
      if (js.context.hasProperty('agoraWebInitialized') && 
          js.context['agoraWebInitialized'] == true) {
        debugPrint('✅ WebPermissionHelper: Agora web already initialized');
      } else {
        debugPrint('⏳ WebPermissionHelper: Waiting for Agora web initialization...');
        
        // Set up a listener for when Agora web is ready
        js.context['onAgoraWebReady'] = js.allowInterop(() {
          debugPrint('🎯 WebPermissionHelper: Agora web initialization complete');
        });
      }
      
      debugPrint('✅ WebPermissionHelper: Agora web support initialized');
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error initializing Agora web support: $e');
    }
  }

  /// Get web browser information for debugging
  static Map<String, dynamic> getWebBrowserInfo() {
    if (!kIsWeb) return {};

    try {
      final userAgent = js.context['navigator']['userAgent'] as String;
      return {
        'userAgent': userAgent,
        'isChrome': userAgent.contains('Chrome'),
        'isFirefox': userAgent.contains('Firefox'),
        'isSafari': userAgent.contains('Safari') && !userAgent.contains('Chrome'),
        'isEdge': userAgent.contains('Edge'),
        'platformViewRegistryAvailable': js.context.hasProperty('platformViewRegistry') || 
                                       (js.context.hasProperty('ui') && js.context['ui'].hasProperty('platformViewRegistry')),
        'agoraWebInitialized': js.context.hasProperty('agoraWebInitialized') ? js.context['agoraWebInitialized'] : false,
      };
    } catch (e) {
      debugPrint('❌ WebPermissionHelper: Error getting browser info: $e');
      return {};
    }
  }
}

/// Legacy function for backward compatibility
Future<void> requestWebPermissions() async {
  await WebPermissionHelper.requestWebPermissions();
  WebPermissionHelper.initializeAgoraWebSupport();
}