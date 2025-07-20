import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import '../../features/call/domain/models/call_model.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../config/agora_config.dart';
import 'service_locator.dart';

enum CallServiceState {
  idle,
  initializing,
  ready,
  connecting,
  connected,
  disconnecting,
  error
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Agora RTC Engine
  RtcEngine? _engine;
  
  // Current state
  CallServiceState _state = CallServiceState.idle;
  CallModel? _currentCall;
  
  // Stream controllers for state management
  final StreamController<CallServiceState> _stateController = 
      StreamController<CallServiceState>.broadcast();
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Call timer
  Timer? _callTimer;
  int _callDuration = 0;

  // Audio/Video settings
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;

  // Repository
  CallRepository? _callRepository;

  // Getters
  CallServiceState get state => _state;
  CallModel? get currentCall => _currentCall;
  RtcEngine? get engine => _engine;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  int get callDuration => _callDuration;

  // Streams
  Stream<CallServiceState> get stateStream => _stateController.stream;
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;

  /// Initialize the call service
  Future<void> initialize() async {
    if (_state != CallServiceState.idle) {
      if (kDebugMode) {
        print('📞 CallService already initialized or initializing');
      }
      return;
    }

    try {
      _setState(CallServiceState.initializing);
      
      // Get call repository from service locator
      _callRepository = ServiceLocator().callRepositoryOrNull;
      
      if (_callRepository == null) {
        throw StateError('CallRepository not available in ServiceLocator');
      }

      // Initialize Agora RTC Engine
      if (kIsWeb) {
        // For web platform, the Agora SDK requires additional setup
        // Ensure iris-web-rtc script is loaded in index.html
        if (kDebugMode) {
          print('📱 Initializing Agora for web platform');
        }
      }
      
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set up event handlers
      _setupEventHandlers();

      // Configure audio/video settings
      await _configureAudioVideo();

      _setState(CallServiceState.ready);
      
      if (kDebugMode) {
        print('✅ CallService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CallService initialization failed: $e');
      }
      _setState(CallServiceState.error);
      rethrow;
    }
  }

  /// Set up Agora event handlers
  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        if (kDebugMode) {
          print('📞 Successfully joined channel: ${connection.channelId}');
        }
        _callEventController.add({
          'type': 'joinChannelSuccess',
          'channelId': connection.channelId,
          'elapsed': elapsed,
        });
      },
      
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        if (kDebugMode) {
          print('📞 Remote user joined: $remoteUid');
        }
        _callEventController.add({
          'type': 'userJoined',
          'remoteUid': remoteUid,
          'elapsed': elapsed,
        });
        
        // Start call timer when remote user joins
        _startCallTimer();
        _updateCallStatus(CallStatus.connected, startedAt: DateTime.now());
      },
      
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        if (kDebugMode) {
          print('📞 Remote user left: $remoteUid, reason: ${reason.name}');
        }
        _callEventController.add({
          'type': 'userOffline',
          'remoteUid': remoteUid,
          'reason': reason.name,
        });
      },
      
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        if (kDebugMode) {
          print('📞 Left channel: ${connection.channelId}');
        }
        _callEventController.add({
          'type': 'leaveChannel',
          'stats': stats,
        });
        _stopCallTimer();
      },
      
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        if (kDebugMode) {
          print('📞 Connection state changed: ${state.name}, reason: ${reason.name}');
        }
        _callEventController.add({
          'type': 'connectionStateChanged',
          'state': state.name,
          'reason': reason.name,
        });
      },
      
      onError: (ErrorCodeType err, String msg) {
        if (kDebugMode) {
          print('❌ Agora error: ${err.name}, message: $msg');
        }
        _callEventController.add({
          'type': 'error',
          'errorCode': err.name,
          'message': msg,
        });
      },
      
      onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        if (kDebugMode) {
          print('📞 Remote video state changed: $remoteUid, state: ${state.name}');
        }
        _callEventController.add({
          'type': 'remoteVideoStateChanged',
          'remoteUid': remoteUid,
          'state': state.name,
          'reason': reason.name,
        });
      },
      
      onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
        if (kDebugMode) {
          print('📞 Remote audio state changed: $remoteUid, state: ${state.name}');
        }
        _callEventController.add({
          'type': 'remoteAudioStateChanged',
          'remoteUid': remoteUid,
          'state': state.name,
          'reason': reason.name,
        });
      },
    ));
  }

  /// Configure audio and video settings
  Future<void> _configureAudioVideo() async {
    if (_engine == null) return;

    // Enable audio
    await _engine!.enableAudio();
    
    // Set audio profile
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    // Enable video
    await _engine!.enableVideo();
    
    // Set video encoder configuration
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: AgoraConfig.videoWidth, height: AgoraConfig.videoHeight),
        frameRate: AgoraConfig.videoFrameRate,
        bitrate: AgoraConfig.videoBitrate,
      ),
    );

    if (kDebugMode) {
      print('📞 Audio/Video configuration completed');
    }
  }

  /// Request necessary permissions
  Future<bool> requestPermissions(CallType callType) async {
    try {
      // On web, permissions are handled differently by the browser
      if (kIsWeb) {
        if (kDebugMode) {
          print('📱 Web platform: permissions handled by browser');
        }
        return true; // Assume granted on web, browser will prompt if needed
      }
      
      final permissions = <Permission>[
        Permission.microphone,
      ];

      if (callType == CallType.video) {
        permissions.add(Permission.camera);
      }

      final statuses = await permissions.request();
      
      bool allGranted = true;
      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          allGranted = false;
          if (kDebugMode) {
            print('❌ Permission denied: ${permission.toString()}');
          }
        }
      }

      return allGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Start an outgoing call
  Future<CallModel> startCall({
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    if (_state != CallServiceState.ready) {
      throw StateError('CallService not ready. Current state: $_state');
    }

    if (_currentCall != null) {
      throw StateError('Already in a call');
    }

    try {
      // Request permissions
      final hasPermissions = await requestPermissions(callType);
      if (!hasPermissions) {
        throw StateError('Required permissions not granted');
      }

      _setState(CallServiceState.connecting);

      // Get current user ID (assuming it's available from auth service)
      final authService = ServiceLocator().authProviderOrNull;
      if (authService?.currentUser == null) {
        throw StateError('User not authenticated');
      }
      
      final callerId = authService!.currentUser!.uid;

      // Create call in repository
      final call = await _callRepository!.initiateCall(
        callerId: callerId,
        receiverId: receiverId,
        callType: callType,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      _currentCall = call;
      _currentCallController.add(_currentCall);

      // Join Agora channel
      await _joinChannel(call.channelName, callType);

      // Update call status to ringing (for receiver)
      await _updateCallStatus(CallStatus.ringing);

      if (kDebugMode) {
        print('📞 Outgoing call started: ${call.callId}');
      }

      return call;
    } catch (e) {
      _setState(CallServiceState.ready);
      if (kDebugMode) {
        print('❌ Failed to start call: $e');
      }
      rethrow;
    }
  }

  /// Answer an incoming call
  Future<void> answerCall(CallModel call) async {
    if (_state != CallServiceState.ready) {
      throw StateError('CallService not ready. Current state: $_state');
    }

    try {
      // Request permissions
      final hasPermissions = await requestPermissions(call.callType);
      if (!hasPermissions) {
        throw StateError('Required permissions not granted');
      }

      _setState(CallServiceState.connecting);
      _currentCall = call;
      _currentCallController.add(_currentCall);

      // Join Agora channel
      await _joinChannel(call.channelName, call.callType);

      // Update call status to connecting
      await _updateCallStatus(CallStatus.connecting);

      if (kDebugMode) {
        print('📞 Answered call: ${call.callId}');
      }
    } catch (e) {
      _setState(CallServiceState.ready);
      if (kDebugMode) {
        print('❌ Failed to answer call: $e');
      }
      rethrow;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    try {
      await _callRepository!.updateCallStatus(
        call.callId,
        CallStatus.declined,
        endedAt: DateTime.now(),
        endReason: CallEndReason.declined,
      );

      if (kDebugMode) {
        print('📞 Declined call: ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to decline call: $e');
      }
      rethrow;
    }
  }

  /// End the current call
  Future<void> endCall([CallEndReason reason = CallEndReason.normal]) async {
    if (_currentCall == null) {
      if (kDebugMode) {
        print('📞 No active call to end');
      }
      return;
    }

    try {
      _setState(CallServiceState.disconnecting);

      // Leave Agora channel
      await _leaveChannel();

      // Update call status
      await _callRepository!.endCall(_currentCall!.callId, reason);
      
      // Stop call timer
      _stopCallTimer();

      // Clear current call
      _currentCall = null;
      _currentCallController.add(null);

      _setState(CallServiceState.ready);

      if (kDebugMode) {
        print('📞 Call ended successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error ending call: $e');
      }
      _setState(CallServiceState.ready);
    }
  }

  /// Join Agora channel
  Future<void> _joinChannel(String channelName, CallType callType) async {
    if (_engine == null) {
      throw StateError('Agora engine not initialized');
    }

    try {
      // Configure video based on call type
      if (callType == CallType.audio) {
        await _engine!.disableVideo();
        _isVideoEnabled = false;
      } else {
        await _engine!.enableVideo();
        _isVideoEnabled = true;
      }

      // Join channel (no token for Phase 1)
      await _engine!.joinChannel(
        token: "", // No token in Phase 1
        channelId: channelName,
        uid: 0, // Let Agora assign UID
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _setState(CallServiceState.connected);
      
      if (kDebugMode) {
        print('📞 Joined channel: $channelName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to join channel: $e');
      }
      rethrow;
    }
  }

  /// Leave Agora channel
  Future<void> _leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      if (kDebugMode) {
        print('📞 Left channel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error leaving channel: $e');
      }
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (_engine == null) return;

    try {
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
      
      if (kDebugMode) {
        print('📞 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling mute: $e');
      }
    }
  }

  /// Toggle video
  Future<void> toggleVideo() async {
    if (_engine == null) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      
      if (kDebugMode) {
        print('📞 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling video: $e');
      }
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;

    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
      
      if (kDebugMode) {
        print('📞 Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling speaker: $e');
      }
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      await _engine!.switchCamera();
      if (kDebugMode) {
        print('📞 Camera switched');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error switching camera: $e');
      }
    }
  }

  /// Start call timer
  void _startCallTimer() {
    _callDuration = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
    });
  }

  /// Stop call timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    
    // Update call duration in repository
    if (_currentCall != null && _callDuration > 0) {
      _callRepository?.updateCallStatus(
        _currentCall!.callId,
        _currentCall!.status,
        duration: _callDuration,
      );
    }
  }

  /// Update call status
  Future<void> _updateCallStatus(CallStatus status, {DateTime? startedAt}) async {
    if (_currentCall == null || _callRepository == null) return;

    try {
      await _callRepository!.updateCallStatus(
        _currentCall!.callId,
        status,
        startedAt: startedAt,
      );
      
      _currentCall = _currentCall!.copyWith(status: status, startedAt: startedAt);
      _currentCallController.add(_currentCall);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating call status: $e');
      }
    }
  }

  /// Set state
  void _setState(CallServiceState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await endCall();
    await _engine?.release();
    _engine = null;
    
    _stateController.close();
    _currentCallController.close();
    _callEventController.close();
    
    _stopCallTimer();
  }
}