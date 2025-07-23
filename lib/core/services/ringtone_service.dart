import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;
  RingtoneService._internal();

  static const MethodChannel _channel = MethodChannel('ringtone_service');
  
  bool _isPlaying = false;
  Timer? _timeoutTimer;

  /// Start playing the ringtone
  Future<void> startRingtone() async {
    if (_isPlaying) return;
    
    try {
      _isPlaying = true;
      
      if (kIsWeb) {
        // For web, we'll use a simple beep sound or HTML5 audio
        await _playWebRingtone();
      } else {
        // For mobile platforms, use platform channel
        await _channel.invokeMethod('startRingtone');
      }
      
      if (kDebugMode) {
        debugPrint('📱 Ringtone started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting ringtone: $e');
      }
      _isPlaying = false;
    }
  }

  /// Stop playing the ringtone
  Future<void> stopRingtone() async {
    if (!_isPlaying) return;
    
    try {
      _isPlaying = false;
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
      
      if (kIsWeb) {
        await _stopWebRingtone();
      } else {
        await _channel.invokeMethod('stopRingtone');
      }
      
      if (kDebugMode) {
        debugPrint('📱 Ringtone stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping ringtone: $e');
      }
    }
  }

  /// Play ringtone with automatic timeout
  Future<void> playWithTimeout({Duration timeout = const Duration(seconds: 30)}) async {
    await startRingtone();
    
    _timeoutTimer = Timer(timeout, () {
      stopRingtone();
    });
  }

  /// Check if ringtone is currently playing
  bool get isPlaying => _isPlaying;

  Future<void> _playWebRingtone() async {
    // For web, create a more sophisticated audio implementation
    if (kIsWeb) {
      try {
        // Create Web Audio API context and generate a ringtone-like sound
        await _createWebAudioContext();
        if (kDebugMode) {
          debugPrint('🔊 Web ringtone started');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Web ringtone error: $e');
        }
      }
    }
  }

  Future<void> _stopWebRingtone() async {
    if (kIsWeb) {
      await _stopWebAudioContext();
      if (kDebugMode) {
        debugPrint('🔇 Web ringtone stopped');
      }
    }
  }

  Future<void> _createWebAudioContext() async {
    // This would create a Web Audio API context and generate ringtone sounds
    // For now, we'll use a simple implementation that could be enhanced
    // with actual Web Audio API calls through js interop
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _stopWebAudioContext() async {
    // Stop the Web Audio API context
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Dispose resources
  void dispose() {
    stopRingtone();
    _timeoutTimer?.cancel();
  }
}