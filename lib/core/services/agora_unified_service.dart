import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';
import '../agora/cross_platform_video_view.dart';

/// Unified cross-platform Agora service using agora_rtc_engine 6.5.2
/// Supports Android, iOS, Web, Windows, Linux, macOS with proper video rendering
class AgoraUnifiedService implements AgoraServiceInterface {
  static final AgoraUnifiedService _instance = AgoraUnifiedService._internal();
  factory AgoraUnifiedService() => _instance;
  AgoraUnifiedService._internal();

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
  
  // Token service
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
    // Handle Web platform differently - don't initialize Agora but mark as initialized
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedService: Web platform - skipping Agora initialization (calling disabled)');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🚀 AgoraUnifiedService: Initializing with agora_rtc_engine...');
      
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Successfully joined channel: ${connection.channelId}');
          _callEventController.add({
            'type': 'channelJoined',
            'channelId': connection.channelId,
            'uid': connection.localUid,
            'elapsed': elapsed,
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (kDebugMode) debugPrint('👥 AgoraUnifiedService: User joined - UID: $remoteUid');
          _remoteUsers.add(remoteUid);
          _callEventController.add({
            'type': 'userJoined',
            'uid': remoteUid,
            'elapsed': elapsed,
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (kDebugMode) debugPrint('👋 AgoraUnifiedService: User offline - UID: $remoteUid, Reason: $reason');
          _remoteUsers.remove(remoteUid);
          _callEventController.add({
            'type': 'userOffline',
            'uid': remoteUid,
            'reason': reason.toString(),
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          if (kDebugMode) debugPrint('🔑 AgoraUnifiedService: Token will expire soon');
          _callEventController.add({
            'type': 'tokenWillExpire',
            'token': token,
          });
        },
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Error occurred - Code: $err, Message: $msg');
          _callEventController.add({
            'type': 'error',
            'errorCode': err.toString(),
            'message': msg,
          });
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          if (kDebugMode) debugPrint('🔗 AgoraUnifiedService: Connection state changed - State: $state, Reason: $reason');
          _callEventController.add({
            'type': 'connectionStateChanged',
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          if (kDebugMode) debugPrint('📹 AgoraUnifiedService: Remote video state changed - UID: $remoteUid, State: $state');
          _callEventController.add({
            'type': 'remoteVideoStateChanged',
            'uid': remoteUid,
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
        onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
          if (kDebugMode) debugPrint('🎤 AgoraUnifiedService: Remote audio state changed - UID: $remoteUid, State: $state');
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

      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora RTC Engine: $e');
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (kIsWeb) {
        // On web, permissions are handled by the browser automatically
        if (kDebugMode) debugPrint('🌐 AgoraUnifiedService: Web permissions handled by browser');
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
          if (kDebugMode) debugPrint('⚠️ AgoraUnifiedService: Permission denied for $permission');
        }
      }

      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Permissions check result: $allGranted');
      return allGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    // Disable calling on Web platform
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedService: joinCall disabled on Web platform');
      throw UnsupportedError('Video calling is not supported on Web platform. Please use the mobile or desktop app.');
    }

    try {
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }

      if (kDebugMode) {
        debugPrint('📞 AgoraUnifiedService: Joining ${callType.name} call');
        debugPrint('🔗 Channel: $channelName');
        debugPrint('🆔 UID: $uid');
        debugPrint('📱 Platform: ${_getPlatformName()}');
      }

      // Check permissions
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted for ${callType.name} call');
      }

      // Get token from Supabase
      final token = await _tokenService.getToken(
        channelName: channelName,
        uid: uid ?? 0,
        callType: callType,
      );

      // Set media options based on call type
      _isVideoEnabled = callType == CallType.video;
      _isAudioEnabled = true;

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
        uid: uid ?? 0,
        options: options,
      );
      
      // Update state
      _currentChannelName = channelName;
      _currentUid = uid ?? 0;
      _isInCall = true;

      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Successfully joined ${callType.name} call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to join call: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    // On Web platform, nothing to leave
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedService: leaveCall - nothing to do on Web platform');
      return;
    }

    try {
      if (_engine == null) return;

      if (kDebugMode) debugPrint('🚪 AgoraUnifiedService: Leaving call...');

      await _engine!.leaveChannel();
      
      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();

      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to leave call: $e');
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

      if (kDebugMode) {
        debugPrint('🎤 AgoraUnifiedService: Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to toggle mute: $e');
      rethrow;
    }
  }

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

      if (kDebugMode) {
        debugPrint('📹 AgoraUnifiedService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to toggle video: $e');
      rethrow;
    }
  }

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

      if (kDebugMode) {
        debugPrint('🔊 AgoraUnifiedService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to toggle speaker: $e');
      rethrow;
    }
  }

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

      if (kDebugMode) debugPrint('🔄 AgoraUnifiedService: Camera switched');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to switch camera: $e');
      rethrow;
    }
  }

  @override
  Future<void> renewToken(String token) async {
    try {
      if (_engine == null || _currentChannelName == null) return;

      await _engine!.renewToken(token);

      _callEventController.add({
        'type': 'tokenRenewed',
      });

      if (kDebugMode) debugPrint('🔑 AgoraUnifiedService: Token renewed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to renew token: $e');
      rethrow;
    }
  }

  @override
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    if (_engine == null) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Local Camera Not Available',
        icon: Icons.videocam_off,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return CrossPlatformVideoViewFactory.createLocalVideoView(
      engine: _engine!,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget createRemoteVideoView(int uid, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    if (_engine == null) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Remote Video Not Available',
        icon: Icons.person,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return CrossPlatformVideoViewFactory.createRemoteVideoView(
      engine: _engine!,
      uid: uid,
      channelId: _currentChannelName,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  String _getPlatformName() {
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

  /// Get the RtcEngine for direct access
  RtcEngine? get engine => _engine;

  @override
  void dispose() {
    try {
      _callEventController.close();
      _currentCallController.close();
      _engine?.leaveChannel();
      _engine?.release();
      _engine = null;
      
      if (kDebugMode) debugPrint('🧹 AgoraUnifiedService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Error during dispose: $e');
    }
  }
}