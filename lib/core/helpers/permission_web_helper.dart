// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> requestWebPermissions() async {
  if (!kIsWeb) return;
  
  try {
    final navigator = html.window.navigator;
    if (navigator.mediaDevices != null) {
      print('🔐 Requesting web media permissions...');
      await navigator.mediaDevices!
          .getUserMedia({'audio': true, 'video': true});
      print('✅ Web permissions granted successfully');
    } else {
      print('⚠️ MediaDevices not supported in this browser');
    }
  } catch (e) {
    print('❌ Web permission request failed: $e');
    // Continue anyway as some permissions might be granted later
  }
}

Future<bool> checkWebPermissions() async {
  if (!kIsWeb) return true;
  
  try {
    final navigator = html.window.navigator;
    if (navigator.mediaDevices != null) {
      // Try to get media stream to check permissions
      final stream = await navigator.mediaDevices!
          .getUserMedia({'audio': true, 'video': true});
      
      // Close the stream immediately as we only needed to check
      stream.getTracks().forEach((track) => track.stop());
      return true;
    }
  } catch (e) {
    print('🔍 Web permissions check failed: $e');
    return false;
  }
  
  return false;
}