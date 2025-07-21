import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/call/domain/models/call_model.dart';
import '../config/agora_config.dart';
import 'agora_token_service.dart';
import 'agora_web_compatibility.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  String? _currentToken;
  bool _isInCall = false;
  
  // Video settings
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isFrontCamera = true;
  
  // Token service
  final AgoraTokenService _tokenService = AgoraTokenService();
  
  // Event streams
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();

  // User management
  final Set<int> _remoteUsers = <int>{};
  
  // Getters
  bool get isInCall => _isInCall;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isMuted => !_isAudioEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  String? get currentChannelName => _currentChannelName;
  Set<int> get remoteUsers => Set.from(_remoteUsers);
  
  // Streams
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  /// Initialize Agora RTC Engine
  Future<void> initialize() async {
    try {
      if (_engine != null) {
        if (kDebugMode) {
          debugPrint('🎯 Agora engine already initialized');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🚀 Initializing Agora RTC Engine...');
      }

      // Create engine with platform-specific method
      if (kIsWeb) {
        _engine = createAgoraRtcEngine();
      } else {
        _engine = createAgoraRtcEngine();
      }
      
      // Initialize engine
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set up event handlers
      _setupEventHandlers();

      // Enable audio and video
      await _engine!.enableAudio();
      await _engine!.enableVideo();

      // Set default audio route
      await _engine!.setDefaultAudioRouteToSpeakerphone(false);

      // Configure video settings
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: AgoraConfig.videoWidth,
            height: AgoraConfig.videoHeight,
          ),
          frameRate: AgoraConfig.videoFrameRate,
          bitrate: AgoraConfig.videoBitrate,
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Agora RTC Engine initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Agora engine: $e');
      }
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  /// Set up event handlers for Agora engine
  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (kDebugMode) {
            debugPrint('✅ Joined channel: ${connection.channelId}, uid: ${connection.localUid}');
          }
          
          _callEventController.add({
            'type': 'joinChannelSuccess',
            'channelId': connection.channelId,
            'localUid': connection.localUid,
            'elapsed': elapsed,
          });
        },
        
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (kDebugMode) {
            debugPrint('👤 User joined: $remoteUid');
          }
          
          _remoteUsers.add(remoteUid);
          
          _callEventController.add({
            'type': 'userJoined',
            'remoteUid': remoteUid,
            'elapsed': elapsed,
          });
        },
        
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (kDebugMode) {
            debugPrint('👤 User left: $remoteUid, reason: $reason');
          }
          
          _remoteUsers.remove(remoteUid);
          
          _callEventController.add({
            'type': 'userLeft',
            'remoteUid': remoteUid,
            'reason': reason.toString(),
          });
        },
        
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (kDebugMode) {
            debugPrint('📞 Left channel: ${connection.channelId}');
          }
          
          _callEventController.add({
            'type': 'leaveChannel',
            'channelId': connection.channelId,
            'stats': stats,
          });
        },
        
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) {
            debugPrint('❌ Agora error: $err - $msg');
          }
          
          _callEventController.add({
            'type': 'error',
            'errorCode': err.toString(),
            'message': msg,
          });
        },
        
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          if (kDebugMode) {
            debugPrint('🔗 Connection state changed: $state, reason: $reason');
          }
          
          _callEventController.add({
            'type': 'connectionStateChanged',
            'state': state.toString(),
            'reason': reason.toString(),
          });
        },
        
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          if (kDebugMode) {
            debugPrint('⚠️ Token will expire, renewing...');
          }
          
          // Renew token
          _renewToken();
        },
      ),
    );
  }

  /// Check and request permissions
  Future<bool> checkPermissions(CallType callType) async {
    try {
      // On web, permissions are handled by the browser
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🔐 Web permissions: Browser will handle media permissions');
        }
        return true; // Browser will prompt for permissions
      }
      
      final permissions = <Permission>[Permission.microphone];
      
      if (callType == CallType.video) {
        permissions.add(Permission.camera);
      }

      final statuses = await permissions.request();
      
      final allGranted = statuses.values.every(
        (status) => status == PermissionStatus.granted
      );

      if (kDebugMode) {
        debugPrint('🔐 Permissions check: ${allGranted ? 'Granted' : 'Denied'}');
        for (final entry in statuses.entries) {
          debugPrint('  ${entry.key}: ${entry.value}');
        }
      }

      return allGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking permissions: $e');
      }
      // On web, return true and let browser handle permissions
      return kIsWeb;
    }
  }

  /// Join a call channel
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      if (_engine == null) {
        await initialize();
      }

      // Check permissions
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      if (kDebugMode) {
        debugPrint('🎯 Joining call: $channelName (${callType.name})');
      }

      // Generate token
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _currentToken = tokenResponse.rtcToken;

      // Configure for call type
      if (callType == CallType.video) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
      }

      // Join channel
      await _engine!.joinChannel(
        token: tokenResponse.rtcToken,
        channelId: channelName,
        uid: tokenResponse.uid,
        options: const ChannelMediaOptions(),
      );

      _isInCall = true;

      if (kDebugMode) {
        debugPrint('✅ Successfully joined call: $channelName');
      }
    } catch (e) {
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _currentToken = null;
      
      if (kDebugMode) {
        debugPrint('❌ Failed to join call: $e');
      }
      throw Exception('Failed to join call: $e');
    }
  }

  /// Leave the current call
  Future<void> leaveCall() async {
    try {
      if (_engine == null || !_isInCall) {
        if (kDebugMode) {
          debugPrint('⚠️ No active call to leave');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('📞 Leaving call: $_currentChannelName');
      }

      // Stop video preview
      await _engine!.stopPreview();

      // Leave channel
      await _engine!.leaveChannel();

      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _currentToken = null;
      _remoteUsers.clear();

      _currentCallController.add(null);

      if (kDebugMode) {
        debugPrint('✅ Successfully left call');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error leaving call: $e');
      }
      throw Exception('Failed to leave call: $e');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      if (_engine == null) return;

      _isAudioEnabled = !_isAudioEnabled;
      await _engine!.muteLocalAudioStream(!_isAudioEnabled);

      if (kDebugMode) {
        debugPrint('🎤 Audio ${_isAudioEnabled ? 'unmuted' : 'muted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle mute: $e');
      }
      throw Exception('Failed to toggle mute: $e');
    }
  }

  /// Toggle video
  Future<void> toggleVideo() async {
    try {
      if (_engine == null) return;

      _isVideoEnabled = !_isVideoEnabled;
      
      if (_isVideoEnabled) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
      } else {
        await _engine!.enableLocalVideo(false);
        await _engine!.stopPreview();
      }

      if (kDebugMode) {
        debugPrint('📹 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle video: $e');
      }
      throw Exception('Failed to toggle video: $e');
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      if (_engine == null) return;

      _isSpeakerEnabled = !_isSpeakerEnabled;
      await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);

      if (kDebugMode) {
        debugPrint('🔊 Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle speaker: $e');
      }
      throw Exception('Failed to toggle speaker: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      if (_engine == null) return;

      await _engine!.switchCamera();
      _isFrontCamera = !_isFrontCamera;

      if (kDebugMode) {
        debugPrint('📱 Switched to ${_isFrontCamera ? 'front' : 'back'} camera');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to switch camera: $e');
      }
      throw Exception('Failed to switch camera: $e');
    }
  }

  /// Renew token when it's about to expire
  Future<void> _renewToken() async {
    try {
      if (_currentChannelName == null) return;

      final tokenResponse = await _tokenService.generateToken(
        channelName: _currentChannelName!,
        uid: _currentUid,
      );

      await _engine!.renewToken(tokenResponse.rtcToken);
      _currentToken = tokenResponse.rtcToken;

      if (kDebugMode) {
        debugPrint('✅ Token renewed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to renew token: $e');
      }
    }
  }

  /// Create local video view widget
  Widget createLocalVideoView() {
    if (_engine == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    try {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Video view creation failed: $e');
      }
      // Fallback for web or compatibility issues
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                color: Colors.white54,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb ? 'Web Video Preview' : 'Video Preview',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Create remote video view widget
  Widget createRemoteVideoView(int uid) {
    if (_engine == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Remote video not available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    try {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: _currentChannelName),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Remote video view creation failed: $e');
      }
      // Fallback for web or compatibility issues
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                color: Colors.white54,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb ? 'Web Remote Video (UID: $uid)' : 'Remote Video (UID: $uid)',
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Dispose and cleanup
  void dispose() async {
    try {
      if (_isInCall) {
        await leaveCall();
      }

      await _engine?.release();
      _engine = null;

      _callEventController.close();
      _currentCallController.close();

      if (kDebugMode) {
        debugPrint('🧹 Agora service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disposing Agora service: $e');
      }
    }
  }
}