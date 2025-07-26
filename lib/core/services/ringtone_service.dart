import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Platform-specific imports

class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;
  RingtoneService._internal();

  static const MethodChannel _channel = MethodChannel('ringtone_service');
  
  bool _isPlaying = false;
  Timer? _timeoutTimer;
  Timer? _stopDelayTimer;
  
  // Platform-specific audio service
  AudioServiceInterface? _audioService;

  /// Get the appropriate audio service based on platform
  AudioServiceInterface get audioService {
    if (_audioService == null) {
      if (kIsWeb) {
        _audioService = _createWebAudioService();
      } else {
        _audioService = _createMobileAudioService();
      }
    }
    return _audioService!;
  }
  
  /// Create web audio service
  AudioServiceInterface _createWebAudioService() {
    return _WebAudioServiceImpl();
  }
  
  /// Create mobile audio service
  AudioServiceInterface _createMobileAudioService() {
    return _MobileAudioServiceImpl(_channel);
  }

  /// Start playing the ringtone
  Future<void> startRingtone() async {
    if (_isPlaying) {
      if (kDebugMode) {
        debugPrint('⚠️ Ringtone already playing, skipping');
      }
      return;
    }
    
    try {
      _isPlaying = true;
      
      // Cancel any pending stop operations
      _stopDelayTimer?.cancel();
      _stopDelayTimer = null;
      
      await audioService.startRingtone();
      
      if (kDebugMode) {
        debugPrint('📱 Ringtone started successfully');
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
    if (!_isPlaying) {
      if (kDebugMode) {
        debugPrint('⚠️ Ringtone not playing, skipping stop');
      }
      return;
    }
    
    try {
      // Cancel any timers immediately
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
      _stopDelayTimer?.cancel();
      _stopDelayTimer = null;
      
      await audioService.stopRingtone();
      
      // Always reset playing state
      _isPlaying = false;
      
      if (kDebugMode) {
        debugPrint('📱 Ringtone stopped successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping ringtone: $e');
      }
      // Force reset state even on error
      _isPlaying = false;
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
      _stopDelayTimer?.cancel();
      _stopDelayTimer = null;
    }
  }

  /// Force stop ringtone immediately (emergency stop for call events)
  Future<void> forceStopRingtone() async {
    if (kDebugMode) {
      debugPrint('🚨 Force stopping ringtone immediately');
    }
    
    // Cancel all timers immediately
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _stopDelayTimer?.cancel();
    _stopDelayTimer = null;
    
    // Force reset state immediately to prevent any further playing
    final wasPlaying = _isPlaying;
    _isPlaying = false;
    
    if (!wasPlaying) {
      if (kDebugMode) {
        debugPrint('🔇 Ringtone was not playing, force stop complete');
      }
      return;
    }
    
    try {
      await audioService.forceStopRingtone();
      
      if (kDebugMode) {
        debugPrint('✅ Ringtone force stopped successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error during force stop: $e (state already reset)');
      }
      // Continue - state is already reset
    }
  }

  /// Play ringtone with automatic timeout
  Future<void> playWithTimeout({Duration timeout = const Duration(seconds: 30)}) async {
    await startRingtone();
    
    _timeoutTimer = Timer(timeout, () {
      if (kDebugMode) {
        debugPrint('⏰ Ringtone timeout reached, stopping...');
      }
      forceStopRingtone();
    });
  }

  /// Stop ringtone with delay (for graceful transitions)
  Future<void> stopWithDelay({Duration delay = const Duration(milliseconds: 500)}) async {
    if (!_isPlaying) return;
    
    if (kDebugMode) {
      debugPrint('⏳ Stopping ringtone with ${delay.inMilliseconds}ms delay');
    }
    
    _stopDelayTimer = Timer(delay, () {
      stopRingtone();
    });
  }

  /// Check if ringtone is currently playing
  bool get isPlaying => _isPlaying;

  /// Stop method (alias for stopRingtone for compatibility)
  Future<void> stop() async {
    await stopRingtone();
  }

  /// Play incoming ringtone (alias for startRingtone for compatibility)
  Future<void> playIncomingRingtone() async {
    await startRingtone();
  }

  /// Dispose resources
  void dispose() {
    forceStopRingtone();
    try {
      _audioService?.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  }
}

/// Interface for platform-specific audio services
abstract class AudioServiceInterface {
  Future<void> startRingtone();
  Future<void> stopRingtone();
  Future<void> forceStopRingtone();
  void dispose();
}

/// Mobile-specific audio service using platform channels
class _MobileAudioServiceImpl implements AudioServiceInterface {
  final MethodChannel _channel;
  
  _MobileAudioServiceImpl(this._channel);

  @override
  Future<void> startRingtone() async {
    try {
      await _channel.invokeMethod('startRingtone');
      if (kDebugMode) {
        debugPrint('📱 Mobile ringtone started via platform channel');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting mobile ringtone: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> stopRingtone() async {
    try {
      await _channel.invokeMethod('stopRingtone');
      if (kDebugMode) {
        debugPrint('📱 Mobile ringtone stopped via platform channel');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping mobile ringtone: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> forceStopRingtone() async {
    try {
      // Try force stop method first
      try {
        await _channel.invokeMethod('forceStopRingtone');
      } catch (e) {
        // Fall back to regular stop if force stop method doesn't exist
        await _channel.invokeMethod('stopRingtone');
      }
      
      if (kDebugMode) {
        debugPrint('🚨 Mobile ringtone force stopped via platform channel');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error force stopping mobile ringtone: $e');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    // Nothing to dispose for mobile platform channels
    if (kDebugMode) {
      debugPrint('📱 Mobile audio service disposed');
    }
  }
}

/// Web-specific audio service using package:web (conditional compilation)
class _WebAudioServiceImpl implements AudioServiceInterface {
  Timer? _ringtoneTimer;
  bool _isPlaying = false;

  @override
  Future<void> startRingtone() async {
    if (_isPlaying) return;
    
    try {
      _isPlaying = true;
      
      if (kIsWeb) {
        // Only try web audio on web platform
        await _playWebRingtone();
      } else {
        // Fallback for non-web (shouldn't happen but just in case)
        _playFallbackRingtone();
      }
      
      if (kDebugMode) {
        debugPrint('🔊 Web ringtone started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web Audio API ringtone error: $e');
      }
      // Fallback to simpler audio approach
      _playFallbackRingtone();
    }
  }

  @override
  Future<void> stopRingtone() async {
    await _stopWebRingtone(force: false);
  }

  @override
  Future<void> forceStopRingtone() async {
    await _stopWebRingtone(force: true);
  }

  /// Play web ringtone using Web Audio API (only available on web)
  Future<void> _playWebRingtone() async {
    if (!kIsWeb) return;
    
    // Import web package only on web platform
    // This requires conditional imports to work properly
    try {
      // For now, use a fallback approach since conditional imports are complex
      _playFallbackRingtone();
    } catch (e) {
      _playFallbackRingtone();
    }
  }

  /// Fallback ringtone implementation
  void _playFallbackRingtone() {
    // Simple beep pattern as fallback
    _ringtoneTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      if (kDebugMode) {
        debugPrint('🔔 Ringtone beep (fallback)');
      }
    });
  }

  Future<void> _stopWebRingtone({bool force = false}) async {
    _isPlaying = false;
    
    try {
      // Cancel ringtone timer
      _ringtoneTimer?.cancel();
      _ringtoneTimer = null;
      
      if (kDebugMode) {
        debugPrint('🔇 Web ringtone stopped${force ? ' (forced)' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping web ringtone: $e');
      }
    }
  }

  @override
  void dispose() {
    _isPlaying = false;
    _ringtoneTimer?.cancel();
    _ringtoneTimer = null;
    
    if (kDebugMode) {
      debugPrint('🔇 Web audio service disposed');
    }
  }
}