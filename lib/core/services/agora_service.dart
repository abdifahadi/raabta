import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';

/// Native implementation of Agora service for Android, iOS, Windows, macOS, Linux
class AgoraService implements AgoraServiceInterface {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

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
  Set<int> get remoteUsers => Set.from(_remoteUsers);
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  
  @override
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  @override
  Future<void> initialize() async {
    if (_engine != null) {
      if (kDebugMode) debugPrint('AgoraService: Already initialized');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🎥 AgoraService: Initializing native Agora engine...');
      
      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configure engine settings
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: AgoraConfig.videoWidth,
            height: AgoraConfig.videoHeight,
          ),
          frameRate: AgoraConfig.videoFrameRate,
          bitrate: AgoraConfig.videoBitrate,
        ),
      );

      // Set up event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (kDebugMode) {
              debugPrint('AgoraService: Joined channel: ${connection.channelId}');
            }
            _callEventController.add({
              'type': 'joinChannelSuccess',
              'channel': connection.channelId,
              'uid': connection.localUid,
              'elapsed': elapsed,
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (kDebugMode) {
              debugPrint('AgoraService: User joined: $remoteUid');
            }
            _remoteUsers.add(remoteUid);
            _callEventController.add({
              'type': 'userJoined',
              'uid': remoteUid,
              'elapsed': elapsed,
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (kDebugMode) {
              debugPrint('AgoraService: User left: $remoteUid, reason: ${reason.name}');
            }
            _remoteUsers.remove(remoteUid);
            _callEventController.add({
              'type': 'userLeft',
              'uid': remoteUid,
              'reason': reason.name,
            });
          },
          onError: (ErrorCodeType err, String msg) {
            if (kDebugMode) {
              debugPrint('AgoraService: Error: ${err.name} - $msg');
            }
            _callEventController.add({
              'type': 'error',
              'error': err.name,
              'message': msg,
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            if (kDebugMode) {
              debugPrint('AgoraService: Left channel: ${connection.channelId}');
            }
            _isInCall = false;
            _currentChannelName = null;
            _currentUid = null;
            _remoteUsers.clear();
            _callEventController.add({
              'type': 'leaveChannel',
              'stats': stats,
            });
          },
          onRtcStats: (RtcConnection connection, RtcStats stats) {
            _callEventController.add({
              'type': 'rtcStats',
              'stats': stats,
            });
          },
        ),
      );

      if (kDebugMode) debugPrint('✅ AgoraService: Native engine initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        if (kDebugMode) debugPrint('AgoraService: Microphone permission denied');
        return false;
      }

      // Request camera permission for video calls
      if (callType == CallType.video) {
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          if (kDebugMode) debugPrint('AgoraService: Camera permission denied');
          return false;
        }
      }

      if (kDebugMode) debugPrint('✅ AgoraService: Permissions granted');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Permission check failed: $e');
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
      throw StateError('Agora engine not initialized');
    }

    try {
      if (kDebugMode) {
        debugPrint('AgoraService: Joining call - Channel: $channelName, Type: ${callType.name}');
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

      // Set channel media options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: callType == CallType.video,
        autoSubscribeAudio: true,
        autoSubscribeVideo: callType == CallType.video,
      );

      // Join channel with token
      await _engine!.joinChannel(
        token: tokenResponse.rtcToken,
        channelId: channelName,
        uid: tokenResponse.uid,
        options: options,
      );

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _isInCall = true;

      // Enable/disable video based on call type
      if (callType == CallType.video) {
        await _engine!.enableLocalVideo(true);
        _isVideoEnabled = true;
      } else {
        await _engine!.enableLocalVideo(false);
        _isVideoEnabled = false;
      }

      if (kDebugMode) {
        debugPrint('✅ AgoraService: Successfully joined call');
        debugPrint('🆔 UID: ${tokenResponse.uid}');
        debugPrint('🔐 Token: ${tokenResponse.rtcToken.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to join call: $e');
      throw Exception('Failed to join call: $e');
    }
  }

  @override
  Future<void> leaveCall() async {
    if (_engine == null) return;

    try {
      if (kDebugMode) debugPrint('AgoraService: Leaving call...');
      
      await _engine!.leaveChannel();
      
      if (kDebugMode) debugPrint('✅ AgoraService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to leave call: $e');
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
        debugPrint('AgoraService: Audio ${_isAudioEnabled ? 'unmuted' : 'muted'}');
      }
      
      _callEventController.add({
        'type': 'audioToggled',
        'enabled': _isAudioEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to toggle mute: $e');
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
        debugPrint('AgoraService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
      
      _callEventController.add({
        'type': 'videoToggled',
        'enabled': _isVideoEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to toggle video: $e');
      throw Exception('Failed to toggle video: $e');
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;

    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
      
      if (kDebugMode) {
        debugPrint('AgoraService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
      
      _callEventController.add({
        'type': 'speakerToggled',
        'enabled': _isSpeakerEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to toggle speaker: $e');
      throw Exception('Failed to toggle speaker: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      await _engine!.switchCamera();
      
      if (kDebugMode) debugPrint('AgoraService: Camera switched');
      
      _callEventController.add({
        'type': 'cameraSwitched',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to switch camera: $e');
      throw Exception('Failed to switch camera: $e');
    }
  }

  @override
  Future<void> renewToken(String token) async {
    if (_engine == null || _currentChannelName == null) return;

    try {
      await _engine!.renewToken(token);
      
      if (kDebugMode) debugPrint('✅ AgoraService: Token renewed successfully');
      
      _callEventController.add({
        'type': 'tokenRenewed',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Failed to renew token: $e');
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

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
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

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: _currentChannelName),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _callEventController.close();
      _currentCallController.close();
      _engine?.release();
      _engine = null;
      
      if (kDebugMode) debugPrint('🧹 AgoraService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraService: Error during dispose: $e');
    }
  }
}