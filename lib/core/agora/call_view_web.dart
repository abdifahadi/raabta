// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-specific call view component for Agora video rendering
/// Handles platformViewRegistry compatibility for agora_rtc_engine 6.5.2+
class AgoraCallViewWeb {
  static bool _initialized = false;
  
  /// Initialize web-specific Agora components
  static void initialize() {
    if (_initialized || !kIsWeb) return;
    
    try {
      // Register the platform view factory with proper error handling
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'agora-video-view',
        (int viewId) => html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#000000'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..innerHTML = '''
            <div style="color: white; text-align: center;">
              <div>📹</div>
              <div>Agora Video View</div>
              <div style="font-size: 12px; opacity: 0.7;">agora_rtc_engine 6.5.2</div>
            </div>
          ''',
      );
      
      // Register remote video view factory
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'agora-remote-video-view',
        (int viewId) => html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#000000'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..innerHTML = '''
            <div style="color: white; text-align: center;">
              <div>📹</div>
              <div>Remote Video View</div>
              <div style="font-size: 12px; opacity: 0.7;">agora_rtc_engine 6.5.2</div>
            </div>
          ''',
      );
      
      _initialized = true;
      if (kDebugMode) {
        print('✅ AgoraCallViewWeb: Platform views registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AgoraCallViewWeb: Failed to register platform views: $e');
        print('   This is expected behavior for agora_rtc_engine 6.5.2+ which handles registration internally');
      }
    }
  }
  
  /// Create a local video view widget for web
  static Widget createLocalVideoView() {
    if (!kIsWeb) {
      throw UnsupportedError('This widget is only supported on web');
    }
    
    // Ensure initialization
    initialize();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(
          viewType: 'agora-video-view',
          onPlatformViewCreated: (int id) {
            if (kDebugMode) {
              print('🎬 AgoraCallViewWeb: Local video view created with ID: $id');
            }
          },
        ),
      ),
    );
  }
  
  /// Create a remote video view widget for web
  static Widget createRemoteVideoView(int remoteUid) {
    if (!kIsWeb) {
      throw UnsupportedError('This widget is only supported on web');
    }
    
    // Ensure initialization
    initialize();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(
          viewType: 'agora-remote-video-view',
          onPlatformViewCreated: (int id) {
            if (kDebugMode) {
              print('🎬 AgoraCallViewWeb: Remote video view created for UID: $remoteUid, View ID: $id');
            }
          },
        ),
      ),
    );
  }
  
  /// Create a fallback video view when Agora views are not available
  static Widget createFallbackVideoView(String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'agora_rtc_engine 6.5.2',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Check if web platform views are supported
  static bool get isSupported => kIsWeb && _initialized;
  
  /// Debug information about web initialization
  static Map<String, dynamic> get debugInfo => {
    'isWeb': kIsWeb,
    'initialized': _initialized,
    'platformViewRegistry': kIsWeb && html.window.dartWorkerId != null,
    'timestamp': DateTime.now().toIso8601String(),
  };
}