import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';

import 'agora_service_interface.dart';
import 'agora_service_factory.dart';
import 'service_locator.dart';
import '../config/agora_config.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Use platform-appropriate Agora service
  final AgoraServiceInterface _agoraService = AgoraServiceFactory.getInstance();
  
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
  
  // Current call tracking
  CallModel? _currentCall;
  Timer? _callTimeoutTimer;
  
  // Getters
  bool get isInCall => _agoraService.isInCall;
  bool get isVideoEnabled => _agoraService.isVideoEnabled;
  bool get isMuted => _agoraService.isMuted;
  bool get isSpeakerEnabled => _agoraService.isSpeakerEnabled;
  String? get currentChannelName => _agoraService.currentChannelName;
  CallModel? get currentCall => _currentCall;
  
  // Streams
  Stream<Map<String, dynamic>> get callEventStream => _agoraService.callEventStream;
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

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

  Future<CallModel> startCall({
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    try {
      final callRepository = ServiceLocator().callRepository;
      final authProvider = ServiceLocator().authProvider;
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is already in a call
      if (_currentCall != null && !_currentCall!.isEnded) {
        throw Exception('Already in an active call');
      }

      // Check if receiver is already in a call
      final receiverActiveCall = await callRepository.getActiveCall(receiverId);
      if (receiverActiveCall != null) {
        throw Exception('Recipient is currently in another call');
      }

      // Create call object
      final channelName = AgoraConfig.generateChannelName(currentUser.uid, receiverId);
      final call = CallModel.create(
        callerId: currentUser.uid,
        receiverId: receiverId,
        callType: callType,
        channelName: channelName,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      // Store call in Firestore
      await callRepository.initiateCall(call);

      // Update call status to ringing
      await callRepository.updateCallStatus(call.callId, CallStatus.ringing);
      
      _currentCall = call.copyWith(status: CallStatus.ringing);
      _currentCallController.add(_currentCall);
      
      // Set up timeout for auto-cancellation
      _setupCallTimeout(call.callId, const Duration(seconds: 30));
      
      return _currentCall!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to start call: $e');
      }
      throw Exception('Failed to start call: $e');
    }
  }

  Future<void> answerCall(CallModel call) async {
    try {
      final callRepository = ServiceLocator().callRepository;
      final authProvider = ServiceLocator().authProvider;
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint('CallService: Answering call ${call.callId}');
      }

      // Cancel any existing timeout
      _callTimeoutTimer?.cancel();

      // Update call status to accepted in Firestore
      await callRepository.updateCallStatus(
        call.callId, 
        CallStatus.accepted,
        startedAt: DateTime.now(),
      );

      // Update current call
      _currentCall = call.copyWith(
        status: CallStatus.accepted,
        startedAt: DateTime.now(),
      );
      _currentCallController.add(_currentCall);

      // Join Agora channel
      await joinCall(
        channelName: call.channelName,
        token: '', // Token should be generated properly in production
        uid: currentUser.uid.hashCode, // Use proper UID generation in production
        callType: call.callType,
      );

      // Update status to connected after successfully joining
      await callRepository.updateCallStatus(call.callId, CallStatus.connected);
      _currentCall = _currentCall!.copyWith(status: CallStatus.connected);
      _currentCallController.add(_currentCall);

      if (kDebugMode) {
        debugPrint('CallService: Successfully answered call ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to answer call: $e');
      }
      
      // Update call status to failed if answer fails
      try {
        final callRepository = ServiceLocator().callRepository;
        await callRepository.updateCallStatus(
          call.callId, 
          CallStatus.failed,
          endedAt: DateTime.now(),
          endReason: CallEndReason.networkError,
        );
      } catch (updateError) {
        if (kDebugMode) {
          debugPrint('CallService: Failed to update call status after error: $updateError');
        }
      }
      
      throw Exception('Failed to answer call: $e');
    }
  }

  Future<void> declineCall(CallModel call) async {
    try {
      final callRepository = ServiceLocator().callRepository;
      
      if (kDebugMode) {
        debugPrint('CallService: Declining call ${call.callId}');
      }

      // Cancel any existing timeout
      _callTimeoutTimer?.cancel();

      // Update call status to declined in Firestore
      await callRepository.updateCallStatus(
        call.callId, 
        CallStatus.declined,
        endedAt: DateTime.now(),
        endReason: CallEndReason.declined,
      );

      // Clear current call
      _currentCall = null;
      _currentCallController.add(null);

      // Schedule call document cleanup after 3 seconds
      Timer(const Duration(seconds: 3), () async {
        try {
          await callRepository.deleteCall(call.callId);
          if (kDebugMode) {
            debugPrint('CallService: Call document cleaned up: ${call.callId}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('CallService: Failed to cleanup call document: $e');
          }
        }
      });

      if (kDebugMode) {
        debugPrint('CallService: Successfully declined call ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to decline call: $e');
      }
      throw Exception('Failed to decline call: $e');
    }
  }

  Future<void> cancelCall(CallModel call) async {
    try {
      final callRepository = ServiceLocator().callRepository;
      
      if (kDebugMode) {
        debugPrint('CallService: Cancelling call ${call.callId}');
      }

      // Cancel timeout
      _callTimeoutTimer?.cancel();

      // Update call status to cancelled in Firestore
      await callRepository.updateCallStatus(
        call.callId, 
        CallStatus.cancelled,
        endedAt: DateTime.now(),
        endReason: CallEndReason.cancelled,
      );

      // Clear current call
      _currentCall = null;
      _currentCallController.add(null);

      // Schedule call document cleanup after 3 seconds
      Timer(const Duration(seconds: 3), () async {
        try {
          await callRepository.deleteCall(call.callId);
          if (kDebugMode) {
            debugPrint('CallService: Call document cleaned up: ${call.callId}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('CallService: Failed to cleanup call document: $e');
          }
        }
      });

      if (kDebugMode) {
        debugPrint('CallService: Successfully cancelled call ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to cancel call: $e');
      }
      throw Exception('Failed to cancel call: $e');
    }
  }

  Future<void> timeoutCall(CallModel call) async {
    try {
      final callRepository = ServiceLocator().callRepository;
      
      if (kDebugMode) {
        debugPrint('CallService: Call timed out: ${call.callId}');
      }

      // Cancel any existing timeout
      _callTimeoutTimer?.cancel();

      // Update call status to missed due to timeout
      await callRepository.updateCallStatus(
        call.callId, 
        CallStatus.missed,
        endedAt: DateTime.now(),
        endReason: CallEndReason.timeout,
      );

      // Clear current call
      _currentCall = null;
      _currentCallController.add(null);

      // Schedule call document cleanup after 3 seconds
      Timer(const Duration(seconds: 3), () async {
        try {
          await callRepository.deleteCall(call.callId);
          if (kDebugMode) {
            debugPrint('CallService: Timed out call document cleaned up: ${call.callId}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('CallService: Failed to cleanup timed out call document: $e');
          }
        }
      });

      if (kDebugMode) {
        debugPrint('CallService: Successfully handled call timeout ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CallService: Failed to handle call timeout: $e');
      }
      throw Exception('Failed to handle call timeout: $e');
    }
  }

  void _setupCallTimeout(String callId, Duration timeout) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(timeout, () async {
      try {
        final callRepository = ServiceLocator().callRepository;
        
        if (kDebugMode) {
          debugPrint('CallService: Call timed out: $callId');
        }

        // Update call status to missed/declined due to timeout
        await callRepository.updateCallStatus(
          callId, 
          CallStatus.missed,
          endedAt: DateTime.now(),
          endReason: CallEndReason.timeout,
        );

        // Clear current call
        _currentCall = null;
        _currentCallController.add(null);

        // Schedule call document cleanup after 3 seconds
        Timer(const Duration(seconds: 3), () async {
          try {
            await callRepository.deleteCall(callId);
            if (kDebugMode) {
              debugPrint('CallService: Timed out call document cleaned up: $callId');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('CallService: Failed to cleanup timed out call document: $e');
            }
          }
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('CallService: Failed to handle call timeout: $e');
        }
      }
    });
  }

  Future<void> endCall() async {
    try {
      if (_currentCall != null) {
        final callRepository = ServiceLocator().callRepository;
        final endTime = DateTime.now();
        final startTime = _currentCall!.startedAt ?? _currentCall!.createdAt;
        final duration = endTime.difference(startTime).inSeconds;

        // Update call status to ended
        await callRepository.updateCallStatus(
          _currentCall!.callId,
          CallStatus.ended,
          endedAt: endTime,
          endReason: CallEndReason.normal,
          duration: duration,
        );

        // Clear current call
        _currentCall = null;
        _currentCallController.add(null);
      }

      // Cancel any timeout
      _callTimeoutTimer?.cancel();

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
    _callTimeoutTimer?.cancel();
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