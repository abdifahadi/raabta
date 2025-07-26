import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Conditional import to prevent Agora from being loaded on Web
import 'package:agora_rtc_engine/agora_rtc_engine.dart' if (dart.library.html) '../services/web_stub.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../../features/call/domain/models/call_model.dart';
import 'cross_platform_video_view.dart';
import '../services/agora_service_interface.dart';

/// Unified cross-platform Agora service using agora_rtc_engine 6.5.2
/// Supports Android, iOS, Web, Windows, Linux, macOS with proper video rendering
class AgoraService implements AgoraServiceInterface {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  final Logger _logger = Logger();
  
  // Agora engine
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

  /// Initialize the Agora service
  @override
  Future<void> initialize() async {
    try {
      _logger.i('🚀 AgoraService: Initializing service');
      await initializeEngine('4bfa94cebfb04852951bfdf9858dbc4b');
      _logger.i('✅ AgoraService: Service initialized successfully');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to initialize service: $e');
      throw Exception('Failed to initialize Agora service: $e');
    }
  }

  /// Join a call with specified parameters
  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      _logger.i('📞 AgoraService: Joining call - Channel: $channelName, Type: $callType');
      
      // Check permissions first
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Generate a temporary token for demo purposes
      // In production, this should come from your token server
      const token = ''; // Empty token for testing
      final userId = uid ?? 0;

      await joinChannel(token, channelName, userId);
      
      _logger.i('✅ AgoraService: Successfully joined call');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to join call: $e');
      throw Exception('Failed to join call: $e');
    }
  }

  /// Leave the current call
  @override
  Future<void> leaveCall() async {
    try {
      _logger.i('🚪 AgoraService: Leaving call');
      await leaveChannel();
      _logger.i('✅ AgoraService: Successfully left call');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to leave call: $e');
      throw Exception('Failed to leave call: $e');
    }
  }

  /// Initialize the Agora engine with app ID
  Future<void> initializeEngine(String appId) async {
    try {
      _logger.i('🚀 AgoraService: Initializing engine with appId: $appId');
      
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _logger.i('✅ AgoraService: Successfully joined channel: ${connection.channelId}');
          _callEventController.add({
            'type': 'channelJoined',
            'channelId': connection.channelId,
            'uid': connection.localUid,
            'elapsed': elapsed,
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _logger.i('👥 AgoraService: User joined - UID: $remoteUid');
          _remoteUsers.add(remoteUid);
          _callEventController.add({
            'type': 'userJoined',
            'uid': remoteUid,
            'elapsed': elapsed,
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _logger.i('👋 AgoraService: User offline - UID: $remoteUid, Reason: $reason');
          _remoteUsers.remove(remoteUid);
          _callEventController.add({
            'type': 'userOffline',
            'uid': remoteUid,
            'reason': reason.toString(),
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _logger.w('🔑 AgoraService: Token will expire soon');
          _callEventController.add({
            'type': 'tokenWillExpire',
            'token': token,
          });
        },
        onError: (ErrorCodeType err, String msg) {
          _logger.e('❌ AgoraService: Error occurred - Code: $err, Message: $msg');
          _callEventController.add({
            'type': 'error',
            'errorCode': err.toString(),
            'message': msg,
          });
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          _logger.i('🔗 AgoraService: Connection state changed - State: $state, Reason: $reason');
          _callEventController.add({
            'type': 'connectionStateChanged',
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          _logger.i('📹 AgoraService: Remote video state changed - UID: $remoteUid, State: $state');
          _callEventController.add({
            'type': 'remoteVideoStateChanged',
            'uid': remoteUid,
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
        onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
          _logger.i('🎤 AgoraService: Remote audio state changed - UID: $remoteUid, State: $state');
          _callEventController.add({
            'type': 'remoteAudioStateChanged',
            'uid': remoteUid,
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
      ));

      // Enable video and audio by default
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      
      _logger.i('✅ AgoraService: Engine initialized successfully');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to initialize engine: $e');
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  /// Join a channel with token, channel name, and user ID
  Future<void> joinChannel(String token, String channelName, int uid) async {
    try {
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }

      _logger.i('📞 AgoraService: Joining channel: $channelName with UID: $uid');

      // Set channel media options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: _isVideoEnabled,
        publishMicrophoneTrack: _isAudioEnabled,
        publishScreenTrack: false,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      );

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: options,
      );

      // Update state
      _currentChannelName = channelName;
      _currentUid = uid;
      _isInCall = true;

      _logger.i('✅ AgoraService: Successfully joined channel');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to join channel: $e');
      throw Exception('Failed to join channel: $e');
    }
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    try {
      if (_engine == null) return;

      _logger.i('🚪 AgoraService: Leaving channel...');

      await _engine!.leaveChannel();
      
      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();

      _logger.i('✅ AgoraService: Successfully left channel');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to leave channel: $e');
      throw Exception('Failed to leave channel: $e');
    }
  }

  /// Create local video view using the new cross-platform implementation
  @override
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    try {
      if (_engine == null) {
        return CrossPlatformVideoViewFactory.createPlaceholderView(
          label: 'Camera Not Available',
          icon: Icons.videocam_off,
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      }

      _logger.i('📹 AgoraService: Creating local video view');

      return CrossPlatformVideoViewFactory.createLocalVideoView(
        engine: _engine!,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to create local video view: $e');
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Local Video Error',
        icon: Icons.error_outline,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
  }

  /// Create remote video view using the new cross-platform implementation
  @override
  Widget createRemoteVideoView(int remoteUid, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    try {
      if (_engine == null) {
        return CrossPlatformVideoViewFactory.createPlaceholderView(
          label: 'Remote Video Not Available',
          icon: Icons.person,
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      }

      _logger.i('📹 AgoraService: Creating remote video view for UID: $remoteUid');

      return CrossPlatformVideoViewFactory.createRemoteVideoView(
        engine: _engine!,
        uid: remoteUid,
        channelId: _currentChannelName,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to create remote video view: $e');
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Remote Video Error',
        icon: Icons.error_outline,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
  }

  /// Handle call events (user joined, user offline, etc.)
  void handleEvents() {
    callEventStream.listen((event) {
      final eventType = event['type'] as String;
      _logger.i('📡 AgoraService: Handling event: $eventType');
      
      switch (eventType) {
        case 'userJoined':
          // Handle user joined
          break;
        case 'userOffline':
          // Handle user offline
          break;
        case 'error':
          // Handle error
          break;
        default:
          _logger.d('📡 AgoraService: Unhandled event: $eventType');
      }
    });
  }

  /// Check and request permissions for camera and microphone
  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (kIsWeb) {
        // Web permissions are handled automatically by browser
        _logger.i('🌐 AgoraService: Web permissions handled by browser');
        return true;
      }

      List<Permission> permissions = [Permission.microphone];
      if (callType == CallType.video) {
        permissions.add(Permission.camera);
      }

      final statuses = await permissions.request();
      
      bool allGranted = true;
      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          allGranted = false;
          _logger.w('⚠️ AgoraService: Permission denied for $permission');
        }
      }

      _logger.i('✅ AgoraService: Permissions check result: $allGranted');
      return allGranted;
    } catch (e) {
      _logger.e('❌ AgoraService: Permission check failed: $e');
      return false;
    }
  }

  /// Toggle microphone mute/unmute
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

      _logger.i('🎤 AgoraService: Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to toggle mute: $e');
      throw Exception('Failed to toggle mute: $e');
    }
  }

  /// Toggle video on/off
  @override
  Future<void> toggleVideo() async {
    try {
      if (_engine == null) return;

      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      await _engine!.enableLocalVideo(_isVideoEnabled);

      _callEventController.add({
        'type': 'videoToggled',
        'enabled': _isVideoEnabled,
      });

      _logger.i('📹 AgoraService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to toggle video: $e');
      throw Exception('Failed to toggle video: $e');
    }
  }

  /// Toggle speaker on/off
  @override
  Future<void> toggleSpeaker() async {
    try {
      if (_engine == null) return;

      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (!kIsWeb) {
        await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
      }

      _callEventController.add({
        'type': 'speakerToggled',
        'enabled': _isSpeakerEnabled,
      });

      _logger.i('🔊 AgoraService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to toggle speaker: $e');
      throw Exception('Failed to toggle speaker: $e');
    }
  }

  /// Switch between front and back camera
  @override
  Future<void> switchCamera() async {
    try {
      if (_engine == null) return;

      if (!kIsWeb) {
        await _engine!.switchCamera();
      }

      _callEventController.add({
        'type': 'cameraSwitched',
      });

      _logger.i('🔄 AgoraService: Camera switched');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to switch camera: $e');
      throw Exception('Failed to switch camera: $e');
    }
  }

  /// Renew token when it's about to expire
  @override
  Future<void> renewToken(String token) async {
    try {
      if (_engine == null || _currentChannelName == null) return;

      await _engine!.renewToken(token);

      _callEventController.add({
        'type': 'tokenRenewed',
      });

      _logger.i('🔑 AgoraService: Token renewed successfully');
    } catch (e) {
      _logger.e('❌ AgoraService: Failed to renew token: $e');
      throw Exception('Failed to renew token: $e');
    }
  }

  /// Get the engine instance for direct access
  RtcEngine? get engine => _engine;

  /// Dispose of the service and clean up resources
  @override
  void dispose() {
    try {
      _logger.i('🧹 AgoraService: Disposing...');
      
      _callEventController.close();
      _currentCallController.close();
      _engine?.leaveChannel();
      _engine?.release();
      _engine = null;
      
      _logger.i('✅ AgoraService: Disposed successfully');
    } catch (e) {
      _logger.e('❌ AgoraService: Error during dispose: $e');
    }
  }

  /// Get platform name for logging
  String get platformName {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform detection failed
    }
    return 'Unknown';
  }
}