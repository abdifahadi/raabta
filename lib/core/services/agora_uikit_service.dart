import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';
import '../widgets/agora_video_view_web.dart';

/// Cross-platform Agora service implementation using agora_rtc_engine
/// Supports Web, Android, iOS, Windows, macOS, and Linux
class AgoraUIKitService implements AgoraServiceInterface {
  static final AgoraUIKitService _instance = AgoraUIKitService._internal();
  factory AgoraUIKitService() => _instance;
  AgoraUIKitService._internal();

  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  bool _isInCall = false;
  
  // Media state
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  
  // Event streams
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();

  // User management
  final Set<int> _remoteUsers = <int>{};
  
  // Supabase token service
  final SupabaseAgoraTokenService _tokenService = SupabaseAgoraTokenService();
  
  // Getters
  @override
  bool get isInCall => _isInCall;
  
  @override
  bool get isVideoEnabled => _isVideoEnabled;
  
  @override
  bool get isMuted => !_isAudioEnabled;
  
  @override
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  
  @override
  String? get currentChannelName => _currentChannelName;
  
  @override
  int? get currentUid => _currentUid;
  
  @override
  Set<int> get remoteUsers => Set.from(_remoteUsers);
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  
  @override
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  @override
  Future<void> initialize() async {
    try {
      if (kDebugMode) debugPrint('🎥 AgoraUIKitService: Initializing...');
      
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      
      // Initialize the engine with platform-specific settings
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        logConfig: const LogConfig(level: LogLevel.logLevelInfo),
        // Add web-specific configurations if needed
        audioScenario: kIsWeb 
          ? AudioScenarioType.audioScenarioGameStreaming 
          : AudioScenarioType.audioScenarioDefault,
      ));
      
      // Enable audio and video
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      
      // Use platform-appropriate video configuration
      if (kIsWeb) {
        // Web-optimized settings
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 480),
            frameRate: 15,
            bitrate: 300, // Lower bitrate for web
            orientationMode: OrientationMode.orientationModeFixedPortrait,
          ),
        );
      } else {
        // Native platform settings
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 480),
            frameRate: 15,
            bitrate: 400,
          ),
        );
      }
      
      // Set up event handler
      _engine!.registerEventHandler(_createEventHandler());
      
      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora RTC Engine: $e');
    }
  }

  RtcEngineEventHandler _createEventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (kDebugMode) debugPrint('AgoraUIKitService: Joined channel successfully');
        _callEventController.add({
          'type': 'joinChannelSuccess',
          'channel': connection.channelId,
          'uid': connection.localUid,
        });
      },
      onUserJoined: (connection, uid, elapsed) {
        _remoteUsers.add(uid);
        _callEventController.add({
          'type': 'userJoined',
          'uid': uid,
        });
        if (kDebugMode) debugPrint('AgoraUIKitService: User joined: $uid');
      },
      onUserOffline: (connection, uid, reason) {
        _remoteUsers.remove(uid);
        _callEventController.add({
          'type': 'userLeft',
          'uid': uid,
          'reason': reason.name,
        });
        if (kDebugMode) debugPrint('AgoraUIKitService: User left: $uid');
      },
      onLeaveChannel: (connection, stats) {
        _callEventController.add({
          'type': 'leaveChannel',
        });
        if (kDebugMode) debugPrint('AgoraUIKitService: Left channel');
      },
      onError: (err, msg) {
        if (kDebugMode) debugPrint('AgoraUIKitService: Error $err: $msg');
      },
    );
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (kIsWeb) {
        // Web permissions are handled automatically by the browser
        if (kDebugMode) debugPrint('✅ AgoraUIKitService: Web permissions handled by browser');
        return true;
      }

      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (kDebugMode) debugPrint('AgoraUIKitService: Microphone permission denied');
        return false;
      }

      // Request camera permission for video calls
      if (callType == CallType.video) {
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          if (kDebugMode) debugPrint('AgoraUIKitService: Camera permission denied');
          return false;
        }
      }

      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Permissions granted');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    if (_engine == null) {
      throw Exception('Agora engine not initialized');
    }

    try {
      if (kDebugMode) {
        debugPrint('AgoraUIKitService: Joining call - Channel: $channelName, Type: ${callType.name}');
      }

      // Check permissions
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Generate token via Supabase
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
        role: 'publisher',
      );

      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable/disable video based on call type
      if (callType == CallType.video) {
        _isVideoEnabled = true;
        await _engine!.enableLocalVideo(true);
      } else {
        _isVideoEnabled = false;
        await _engine!.enableLocalVideo(false);
      }

      // Join channel
      await _engine!.joinChannel(
        token: tokenResponse.rtcToken,
        channelId: channelName,
        uid: tokenResponse.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: callType == CallType.video,
          publishCameraTrack: callType == CallType.video,
          publishMicrophoneTrack: true,
        ),
      );

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _isInCall = true;

      if (kDebugMode) {
        debugPrint('✅ AgoraUIKitService: Successfully joined call');
        debugPrint('🆔 UID: ${tokenResponse.uid}');
        debugPrint('🔐 Token: ${tokenResponse.rtcToken.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to join call: $e');
      throw Exception('Failed to join call: $e');
    }
  }

  @override
  Future<void> leaveCall() async {
    if (_engine == null) return;

    try {
      if (kDebugMode) debugPrint('AgoraUIKitService: Leaving call...');
      
      await _engine!.leaveChannel();
      
      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();
      
      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to leave call: $e');
      throw Exception('Failed to leave call: $e');
    }
  }

  @override
  Future<void> toggleMute() async {
    if (_engine == null) return;

    try {
      _isAudioEnabled = !_isAudioEnabled;
      await _engine!.muteLocalAudioStream(!_isAudioEnabled);
      
      if (kDebugMode) {
        debugPrint('AgoraUIKitService: Audio ${_isAudioEnabled ? 'unmuted' : 'muted'}');
      }
      
      _callEventController.add({
        'type': 'audioToggled',
        'enabled': _isAudioEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to toggle mute: $e');
      throw Exception('Failed to toggle mute: $e');
    }
  }

  @override
  Future<void> toggleVideo() async {
    if (_engine == null) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      await _engine!.enableLocalVideo(_isVideoEnabled);
      
      if (kDebugMode) {
        debugPrint('AgoraUIKitService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
      
      _callEventController.add({
        'type': 'videoToggled',
        'enabled': _isVideoEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to toggle video: $e');
      throw Exception('Failed to toggle video: $e');
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;

    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (!kIsWeb) {
        // Speaker toggle not applicable on web
        await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
      }
      
      if (kDebugMode) {
        debugPrint('AgoraUIKitService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
      
      _callEventController.add({
        'type': 'speakerToggled',
        'enabled': _isSpeakerEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to toggle speaker: $e');
      throw Exception('Failed to toggle speaker: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      if (!kIsWeb) {
        // Camera switching not applicable on web in the same way
        await _engine!.switchCamera();
      }
      
      if (kDebugMode) debugPrint('AgoraUIKitService: Camera switched');
      
      _callEventController.add({
        'type': 'cameraSwitched',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to switch camera: $e');
      throw Exception('Failed to switch camera: $e');
    }
  }

  @override
  Future<void> renewToken(String token) async {
    if (_engine == null || _currentChannelName == null) return;

    try {
      await _engine!.renewToken(token);
      
      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Token renewed successfully');
      
      _callEventController.add({
        'type': 'tokenRenewed',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to renew token: $e');
      throw Exception('Failed to renew token: $e');
    }
  }

  @override
  Widget createLocalVideoView() {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: createVideoView(
          VideoViewController(
            rtcEngine: _engine!,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }

  @override
  Widget createRemoteVideoView(int uid) {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Remote video not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: createVideoView(
          VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: _currentChannelName),
          ),
        ),
      ),
    );
  }

  /// Get the RtcEngine for direct access
  RtcEngine? get engine => _engine;

  @override
  void dispose() {
    try {
      _callEventController.close();
      _currentCallController.close();
      _engine?.release();
      _engine = null;
      
      if (kDebugMode) debugPrint('🧹 AgoraUIKitService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Error during dispose: $e');
    }
  }
}