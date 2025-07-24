import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';

/// Web-specific Agora service implementation for agora_rtc_engine 6.5.2+
/// Uses proper web SDK integration with enhanced error handling
class AgoraWebService implements AgoraServiceInterface {
  static final AgoraWebService _instance = AgoraWebService._internal();
  factory AgoraWebService() => _instance;
  AgoraWebService._internal();

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
      if (kDebugMode) debugPrint('🌐 AgoraWebService: Initializing for web...');
      
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      
      // Initialize with web-optimized settings
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        logConfig: const LogConfig(level: LogLevel.logLevelInfo),
        audioScenario: AudioScenarioType.audioScenarioGameStreaming, // Better for web
      ));
      
      // Enable audio and video with web-specific settings
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      
      // Web-optimized video configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 300, // Lower bitrate for web stability
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      
      // Web-specific audio settings - fix the profile parameter issue
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      
      // Set up event handler
      _engine!.registerEventHandler(_createEventHandler());
      
      if (kDebugMode) debugPrint('✅ AgoraWebService: Initialized successfully for web');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora RTC Engine for web: $e');
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (kIsWeb) {
        // On web, permissions are handled by the browser
        // We can attempt to check if media devices are available
        if (kDebugMode) debugPrint('AgoraWebService: Checking permissions for ${callType.name} call on web');
        
        // For web, we'll assume permissions are granted
        // The browser will prompt the user when needed
        return true;
      } else {
        // For other platforms (though this is primarily a web service), check actual permissions
        try {
          List<Permission> permissions = [Permission.microphone];
          if (callType == CallType.video) {
            permissions.add(Permission.camera);
          }
          
          Map<Permission, PermissionStatus> statuses = await permissions.request();
          
          bool allGranted = statuses.values.every((status) => status == PermissionStatus.granted);
          
          if (kDebugMode) debugPrint('AgoraWebService: Permissions check result: $allGranted');
          return allGranted;
        } catch (e) {
          // If permission_handler fails on web or other platforms, assume granted
          if (kDebugMode) debugPrint('⚠️ AgoraWebService: Permission check not supported, assuming granted: $e');
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to check permissions: $e');
      return false;
    }
  }

  @override
  Future<void> renewToken(String token) async {
    try {
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }
      
      if (kDebugMode) debugPrint('AgoraWebService: Renewing token...');
      
      await _engine!.renewToken(token);
      
      if (kDebugMode) debugPrint('✅ AgoraWebService: Token renewed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to renew token: $e');
      rethrow;
    }
  }

  RtcEngineEventHandler _createEventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (kDebugMode) debugPrint('AgoraWebService: Joined channel successfully');
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
        if (kDebugMode) debugPrint('AgoraWebService: User joined: $uid');
      },
      onUserOffline: (connection, uid, reason) {
        _remoteUsers.remove(uid);
        _callEventController.add({
          'type': 'userOffline',
          'uid': uid,
          'reason': reason.name,
        });
        if (kDebugMode) debugPrint('AgoraWebService: User offline: $uid');
      },
      onError: (err, msg) {
        if (kDebugMode) debugPrint('❌ AgoraWebService Error: ${err.name} - $msg');
        _callEventController.add({
          'type': 'error',
          'errorCode': err.name,
          'message': msg,
        });
      },
      onLeaveChannel: (connection, stats) {
        if (kDebugMode) debugPrint('AgoraWebService: Left channel');
        _isInCall = false;
        _currentChannelName = null;
        _currentUid = null;
        _remoteUsers.clear();
        _callEventController.add({
          'type': 'leaveChannel',
          'stats': stats,
        });
      },
    );
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }

      if (kDebugMode) debugPrint('AgoraWebService: Joining ${callType.name} call - Channel: $channelName, UID: $uid');

      // Check permissions first
      bool hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted for ${callType.name} call');
      }

      // Get token from Supabase
      String? token;
      try {
        token = await _tokenService.getToken(channelName, uid ?? 0);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ AgoraWebService: Failed to get token, joining without token: $e');
        token = null; // Allow joining without token for development
      }

      // Set client role before joining
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // Configure media based on call type
      bool enableVideo = callType == CallType.video;
      
      if (enableVideo) {
        await _engine!.startPreview();
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }

      // Join channel with proper named parameters
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid ?? 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: enableVideo,
          publishCameraTrack: enableVideo,
          publishMicrophoneTrack: true,
        ),
      );

      _isInCall = true;
      _currentChannelName = channelName;
      _currentUid = uid ?? 0;
      _isVideoEnabled = enableVideo;

      if (kDebugMode) debugPrint('✅ AgoraWebService: Successfully joined ${callType.name} call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to join call - $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    try {
      if (_engine == null) return;

      if (kDebugMode) debugPrint('AgoraWebService: Leaving call...');

      await _engine!.stopPreview();
      await _engine!.leaveChannel();

      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();

      if (kDebugMode) debugPrint('✅ AgoraWebService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to leave call - $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      if (_engine == null) return;

      _isAudioEnabled = !_isAudioEnabled;
      await _engine!.muteLocalAudioStream(!_isAudioEnabled);

      _callEventController.add({
        'type': 'audioToggled',
        'enabled': _isAudioEnabled,
      });

      if (kDebugMode) debugPrint('AgoraWebService: Microphone ${_isAudioEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to toggle microphone - $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleVideo() async {
    try {
      if (_engine == null) return;

      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);

      _callEventController.add({
        'type': 'videoToggled',
        'enabled': _isVideoEnabled,
      });

      if (kDebugMode) debugPrint('AgoraWebService: Camera ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraWebService: Failed to toggle camera - $e');
      rethrow;
    }
  }

  @override
  Future<void> switchCamera() async {
    // Camera switching not typically supported on web
    if (kDebugMode) debugPrint('AgoraWebService: Camera switching not supported on web');
  }

  @override
  Future<void> toggleSpeaker() async {
    // Speaker toggle is handled differently on web
    _isSpeakerEnabled = !_isSpeakerEnabled;
    
    _callEventController.add({
      'type': 'speakerToggled',
      'enabled': _isSpeakerEnabled,
    });

    if (kDebugMode) debugPrint('AgoraWebService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
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

    // For web, return a placeholder that will be replaced by Agora's web video
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Local Video (Web)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
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

    // For web, return a placeholder that will be replaced by Agora's web video
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Remote Video (Web)\nUID: $uid',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the RtcEngine for direct access
  RtcEngine? get engine => _engine;

  @override
  void dispose() {
    _callEventController.close();
    _currentCallController.close();
    _engine?.release();
    _engine = null;
  }
}