import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'agora_service_factory.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Use platform-appropriate Agora service
  final AgoraServiceInterface _agoraService = AgoraServiceFactory.getInstance();
  
  // Deprecated fields - using AgoraService directly now
  // These are kept for backward compatibility but not used
  
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
  bool get isInCall => _agoraService.isInCall;
  bool get isVideoEnabled => _agoraService.isVideoEnabled;
  bool get isMuted => _agoraService.isMuted;
  bool get isSpeakerEnabled => _agoraService.isSpeakerEnabled;
  String? get currentChannelName => _agoraService.currentChannelName;
  
  // Streams
  Stream<Map<String, dynamic>> get callEventStream => _agoraService.callEventStream;
  Stream<CallModel?> get currentCallStream => _agoraService.currentCallStream;

  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('CallService: Already initialized');
      }
      return;
    }
    
    try {
      // Initialize real Agora service for all platforms including web
      await _agoraService.initialize();
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('CallService: Initialized successfully with Agora (${kIsWeb ? 'Web' : 'Native'} mode)');
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
      // Ensure CallService is initialized before joining
      if (!_isInitialized) {
        if (kDebugMode) {
          debugPrint('CallService: Auto-initializing before joining call');
        }
        await initialize();
      }
      
      // Use real Agora service for all platforms
      await _agoraService.joinCall(
        channelName: channelName,
        callType: callType,
        uid: uid,
      );
      
      if (kDebugMode) {
        debugPrint('CallService: Joined call $channelName successfully with Agora (${kIsWeb ? 'Web' : 'Native'})');
      }
      
    } catch (e) {
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
      // Use real Agora service for all platforms
      await _agoraService.leaveCall();
      
      if (kDebugMode) {
        debugPrint('CallService: Call ended successfully with Agora (${kIsWeb ? 'Web' : 'Native'})');
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
      // Use real Agora service for all platforms
      await _agoraService.toggleMute();
      
      if (kDebugMode) {
        debugPrint('CallService: Audio toggled with Agora (${kIsWeb ? 'Web' : 'Native'})');
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
      // Use real Agora service for all platforms
      await _agoraService.toggleVideo();
      
      if (kDebugMode) {
        debugPrint('CallService: Video toggled with Agora (${kIsWeb ? 'Web' : 'Native'})');
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
      // Use real Agora service for all platforms
      await _agoraService.toggleSpeaker();
      
      if (kDebugMode) {
        debugPrint('CallService: Speaker toggled with Agora (${kIsWeb ? 'Web' : 'Native'})');
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
      // Use real Agora service for all platforms
      await _agoraService.switchCamera();
      
      if (kDebugMode) {
        debugPrint('CallService: Camera switched with Agora (${kIsWeb ? 'Web' : 'Native'})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to switch camera: $e');
      }
      throw Exception('Failed to switch camera: $e');
    }
  }

  void dispose() {
    _agoraService.dispose();
    _callEventController.close();
    _currentCallController.close();
  }
  
  // Additional methods for video views (all platforms)
  Widget? createLocalVideoView() {
    return _agoraService.createLocalVideoView();
  }
  
  Widget? createRemoteVideoView(int uid) {
    return _agoraService.createRemoteVideoView(uid);
  }
}