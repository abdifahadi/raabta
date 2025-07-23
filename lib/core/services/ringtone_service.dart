import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;
  RingtoneService._internal();

  static const MethodChannel _channel = MethodChannel('ringtone_service');
  
  bool _isPlaying = false;
  Timer? _timeoutTimer;
  Timer? _stopDelayTimer;
  
  // Web audio context for playing ringtones
  html.AudioContext? _audioContext;
  html.AudioBufferSourceNode? _sourceNode;
  html.GainNode? _gainNode;

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
      
      if (kIsWeb) {
        // For web, use Web Audio API for better control
        await _playWebRingtone();
      } else {
        // For mobile platforms, use platform channel
        await _channel.invokeMethod('startRingtone');
      }
      
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
      
      if (kIsWeb) {
        await _stopWebRingtone();
      } else {
        await _channel.invokeMethod('stopRingtone');
      }
      
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
      // Try to stop on all platforms
      if (kIsWeb) {
        await _stopWebRingtone(force: true);
      } else {
        await _channel.invokeMethod('stopRingtone');
        // For mobile, also try to invoke a force stop method if available
        try {
          await _channel.invokeMethod('forceStopRingtone');
        } catch (e) {
          // Ignore if method doesn't exist
        }
      }
      
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

  /// Web Audio API implementation for better control
  Future<void> _playWebRingtone() async {
    if (!kIsWeb) return;
    
    try {
      // Create audio context if not exists
      _audioContext ??= html.AudioContext();
      
      if (_audioContext!.state == 'suspended') {
        await _audioContext!.resume();
      }
      
      // Create gain node for volume control
      _gainNode = _audioContext!.createGain();
      _gainNode!.connectNode(_audioContext!.destination!);
      _gainNode!.gain!.value = 0.5; // 50% volume
      
      // Generate a ringtone-like sound using oscillators
      await _generateRingtoneSound();
      
      if (kDebugMode) {
        debugPrint('🔊 Web ringtone started with Web Audio API');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web Audio API ringtone error: $e');
      }
      // Fallback to simpler audio element approach
      await _playWebRingtoneFallback();
    }
  }

  /// Generate ringtone sound using Web Audio API oscillators
  Future<void> _generateRingtoneSound() async {
    if (_audioContext == null || _gainNode == null) return;
    
    // Create a repeating ringtone pattern
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      try {
        // Create oscillator for the ringtone tone
        final oscillator = _audioContext!.createOscillator();
        oscillator.frequency!.value = 800; // 800 Hz tone
        oscillator.type = 'sine';
        
        // Create envelope for the tone
        final now = _audioContext!.currentTime!;
        _gainNode!.gain!.setValueAtTime(0, now);
        _gainNode!.gain!.linearRampToValueAtTime(0.3, now + 0.1);
        _gainNode!.gain!.linearRampToValueAtTime(0, now + 0.3);
        
        oscillator.connectNode(_gainNode!);
        oscillator.start(now);
        oscillator.stop(now + 0.3);
        
        // Second tone after a brief pause
        Timer(const Duration(milliseconds: 400), () {
          if (!_isPlaying) return;
          
          try {
            final oscillator2 = _audioContext!.createOscillator();
            oscillator2.frequency!.value = 1000; // 1000 Hz tone
            oscillator2.type = 'sine';
            
            final now2 = _audioContext!.currentTime!;
            _gainNode!.gain!.setValueAtTime(0, now2);
            _gainNode!.gain!.linearRampToValueAtTime(0.3, now2 + 0.1);
            _gainNode!.gain!.linearRampToValueAtTime(0, now2 + 0.3);
            
            oscillator2.connectNode(_gainNode!);
            oscillator2.start(now2);
            oscillator2.stop(now2 + 0.3);
          } catch (e) {
            if (kDebugMode) debugPrint('Error creating second tone: $e');
          }
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Error creating ringtone oscillator: $e');
      }
    });
  }

  /// Fallback ringtone implementation for web
  Future<void> _playWebRingtoneFallback() async {
    // Simple beep pattern as fallback
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      // This would ideally play an audio file or generate a beep
      if (kDebugMode) {
        debugPrint('🔔 Ringtone beep (fallback)');
      }
    });
  }

  Future<void> _stopWebRingtone({bool force = false}) async {
    if (!kIsWeb) return;
    
    try {
      // Stop any playing source nodes
      _sourceNode?.stop();
      _sourceNode = null;
      
      // Reset gain to prevent clicks
      if (_gainNode != null) {
        _gainNode!.gain!.value = 0;
        _gainNode = null;
      }
      
      // Suspend audio context to free resources
      if (_audioContext != null && _audioContext!.state != 'closed') {
        if (force) {
          // Force close the context for immediate stop
          await _audioContext!.close();
          _audioContext = null;
        } else {
          await _audioContext!.suspend();
        }
      }
      
      if (kDebugMode) {
        debugPrint('🔇 Web ringtone stopped${force ? ' (forced)' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping web ringtone: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    forceStopRingtone();
    _audioContext?.close();
    _audioContext = null;
  }
}