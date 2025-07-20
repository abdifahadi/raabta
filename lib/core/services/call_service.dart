import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  String? _currentChannelName;
  bool _isInCall = false;
  
  // Video settings
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  
  // Callbacks
  Function(String userId)? onUserJoined;
  Function(String userId)? onUserLeft;
  Function(String message)? onError;
  
  // Stream controllers for events
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Additional streams for backward compatibility
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();
  
  // Getters
  bool get isInCall => _isInCall;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isMuted => !_isAudioEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  String? get currentChannelName => _currentChannelName;
  
  // Streams
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  Future<void> initialize() async {
    try {
      // For web compatibility, we'll use mock implementation
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('CallService: Web mode - using mock implementation');
        }
        return;
      }
      
      // In a real implementation, we would initialize the actual engine here
      if (kDebugMode) {
        debugPrint('CallService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to initialize: $e');
      }
      throw Exception('Failed to initialize call service: $e');
    }
  }

  Future<void> joinCall({
    required String channelName,
    required String token,
    required int uid,
    required CallType callType,
  }) async {
    try {
      _currentChannelName = channelName;
      _isInCall = true;
      
      if (kIsWeb) {
        // Mock join call for web
        if (kDebugMode) {
          debugPrint('CallService: Mock joining call $channelName');
        }
        
        // Simulate successful join
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate remote user joining after a delay
        Timer(const Duration(seconds: 2), () {
          _callEventController.add({
            'type': 'userJoined',
            'remoteUid': 12345,
          });
        });
        
        return;
      }
      
      // Real implementation would go here
      if (kDebugMode) {
        debugPrint('CallService: Joined call $channelName successfully');
      }
      
    } catch (e) {
      _isInCall = false;
      _currentChannelName = null;
      if (kDebugMode) {
        debugPrint('CallService: Failed to join call: $e');
      }
      throw Exception('Failed to join call: $e');
    }
  }

  // Mock methods for backward compatibility
  Future<CallModel> startCall({
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    // Mock implementation for web compatibility
    final call = CallModel(
      callId: 'mock_call_${DateTime.now().millisecondsSinceEpoch}',
      callerId: 'current_user',
      receiverId: receiverId,
      callType: callType,
      status: CallStatus.ringing,
      channelName: 'mock_channel_${DateTime.now().millisecondsSinceEpoch}',
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
      createdAt: DateTime.now(),
    );
    
    _currentCallController.add(call);
    return call;
  }

  Future<void> answerCall(CallModel call) async {
    // Mock implementation
    if (kDebugMode) {
      debugPrint('CallService: Mock answering call ${call.callId}');
    }
    await joinCall(
      channelName: call.channelName,
      token: '',
      uid: 0,
      callType: call.callType,
    );
  }

  Future<void> declineCall(CallModel call) async {
    // Mock implementation
    if (kDebugMode) {
      debugPrint('CallService: Mock declining call ${call.callId}');
    }
    _currentCallController.add(null);
  }

  Future<void> endCall() async {
    try {
      if (kIsWeb) {
        // Mock end call for web
        if (kDebugMode) {
          debugPrint('CallService: Mock ending call');
        }
        _isInCall = false;
        _currentChannelName = null;
        _currentCallController.add(null);
        return;
      }
      
      // Real implementation would go here
      _isInCall = false;
      _currentChannelName = null;
      _currentCallController.add(null);
      
      if (kDebugMode) {
        debugPrint('CallService: Call ended successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to end call: $e');
      }
      throw Exception('Failed to end call: $e');
    }
  }

  Future<void> toggleMute() async {
    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('CallService: Mock toggled audio: ${_isAudioEnabled ? 'unmuted' : 'muted'}');
        }
        return;
      }
      
      // Real implementation would go here
      if (kDebugMode) {
        debugPrint('CallService: Audio ${_isAudioEnabled ? 'unmuted' : 'muted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to toggle mute: $e');
      }
      throw Exception('Failed to toggle mute: $e');
    }
  }

  Future<void> toggleVideo() async {
    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('CallService: Mock toggled video: ${_isVideoEnabled ? 'enabled' : 'disabled'}');
        }
        return;
      }
      
      // Real implementation would go here
      if (kDebugMode) {
        debugPrint('CallService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to toggle video: $e');
      }
      throw Exception('Failed to toggle video: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('CallService: Mock toggled speaker: ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
        }
        return;
      }
      
      // Real implementation would go here
      if (kDebugMode) {
        debugPrint('CallService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to toggle speaker: $e');
      }
      throw Exception('Failed to toggle speaker: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('CallService: Mock camera switch');
        }
        return;
      }
      
      // Real implementation would go here
      if (kDebugMode) {
        debugPrint('CallService: Camera switched');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to switch camera: $e');
      }
      throw Exception('Failed to switch camera: $e');
    }
  }

  void dispose() {
    _callEventController.close();
    _currentCallController.close();
  }
}