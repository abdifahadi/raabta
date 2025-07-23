import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
// Conditional import to avoid agora_rtc_engine on Web
import 'agora_rtc_engine_stub.dart'
    if (dart.library.io) 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/call/domain/models/call_model.dart';
import '../config/agora_config.dart';
import 'supabase_agora_token_service.dart';

import 'agora_service_interface.dart';

class AgoraService implements AgoraServiceInterface {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  bool _isInCall = false;
  
  // Video settings
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isFrontCamera = true;
  
  // Supabase token service
  final SupabaseAgoraTokenService _tokenService = SupabaseAgoraTokenService();
  
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
  Set<int> get remoteUsers => Set.from(_remoteUsers);
  
  // Streams
  @override
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  @override
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  /// Initialize Agora RTC Engine
  @override
  Future<void> initialize() async {
    try {
      // Prevent initialization on Web platform
      if (kIsWeb) {
        throw UnsupportedError('AgoraService should not be used on Web platform. Use AgoraWebService instead.');
      }
      
      if (_engine != null) {
        if (kDebugMode) {
          debugPrint('🎯 Agora engine already initialized');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🚀 Initializing Agora RTC Engine...');
      }

      // Create engine
      _engine = createAgoraRtcEngine();
      
      // Initialize engine with proper configuration
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        logConfig: LogConfig(
          level: LogLevel.logLevelWarn,
          filePath: '', // Use default log path
        ),
      ));

      // Set up event handlers BEFORE enabling audio/video
      _setupEventHandlers();

      // Enable audio (always needed)
      await _engine!.enableAudio();
      
      // Enable video (will be configured per call type)
      await _engine!.enableVideo();

      // Set default audio route (earpiece by default)
      await _engine!.setDefaultAudioRouteToSpeakerphone(false);

      // Configure video settings with sensible defaults
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: AgoraConfig.videoWidth,
            height: AgoraConfig.videoHeight,
          ),
          frameRate: AgoraConfig.videoFrameRate,
          bitrate: AgoraConfig.videoBitrate,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // Set client role for communication scenario
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      if (kDebugMode) {
        debugPrint('✅ Agora RTC Engine initialized successfully');
      }
    } catch (e) {
      // Reset engine on initialization failure
      _engine = null;
      
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
  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      // On web, permissions are handled by the browser
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🔐 Web permissions: Browser will handle media permissions');
        }
        return true; // Browser will prompt for permissions when needed
      }
      
      final permissions = <Permission>[Permission.microphone];
      
      if (callType == CallType.video) {
        permissions.add(Permission.camera);
      }

      // First check current permission status
      final currentStatuses = <Permission, PermissionStatus>{};
      for (final permission in permissions) {
        currentStatuses[permission] = await permission.status;
      }

      // Request permissions for those that are not granted
      final permissionsToRequest = <Permission>[];
      for (final entry in currentStatuses.entries) {
        if (entry.value != PermissionStatus.granted) {
          permissionsToRequest.add(entry.key);
        }
      }

      if (permissionsToRequest.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔐 Requesting permissions: ${permissionsToRequest.map((p) => p.toString()).join(', ')}');
        }
        
        final requestedStatuses = await permissionsToRequest.request();
        
        // Combine current and requested statuses
        for (final entry in requestedStatuses.entries) {
          currentStatuses[entry.key] = entry.value;
        }
      }
      
      final allGranted = currentStatuses.values.every(
        (status) => status == PermissionStatus.granted
      );

      if (kDebugMode) {
        debugPrint('🔐 Permissions check result: ${allGranted ? 'All Granted' : 'Some Denied'}');
        for (final entry in currentStatuses.entries) {
          debugPrint('  ${entry.key.toString().split('.').last}: ${entry.value.toString().split('.').last}');
        }
      }

      if (!allGranted) {
        // Check for permanently denied permissions
        final permanentlyDenied = currentStatuses.entries
            .where((entry) => entry.value == PermissionStatus.permanentlyDenied)
            .map((entry) => entry.key.toString().split('.').last)
            .toList();
            
        if (permanentlyDenied.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ Permanently denied permissions: ${permanentlyDenied.join(', ')}');
          }
          throw Exception('Permissions permanently denied: ${permanentlyDenied.join(', ')}. Please enable them in device settings.');
        }
      }

      return allGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking permissions: $e');
      }
      // On web, return true and let browser handle permissions
      if (kIsWeb) {
        return true;
      }
      
      // Re-throw the exception for native platforms
      rethrow;
    }
  }

  /// Join a call channel
  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      // Ensure engine is initialized
      if (_engine == null) {
        if (kDebugMode) {
          debugPrint('🔧 Engine not initialized, initializing now...');
        }
        await initialize();
      }

      if (_engine == null) {
        throw Exception('Failed to initialize Agora engine');
      }

      // Check if already in a call
      if (_isInCall) {
        throw Exception('Already in a call. Please end current call first.');
      }

      if (kDebugMode) {
        debugPrint('🎯 Joining call: $channelName (${callType.name})');
      }

      // Check permissions BEFORE generating token
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Required microphone and camera permissions not granted. Please enable permissions in settings.');
      }

      // Generate token with better error handling
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );

      if (kDebugMode) {
        debugPrint('🔑 Token generated: ${tokenResponse.toString()}');
      }

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;

      // Configure engine for call type
      if (callType == CallType.video) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
        _isVideoEnabled = true;
      } else {
        await _engine!.enableLocalVideo(false);
        await _engine!.stopPreview();
        _isVideoEnabled = false;
      }

      // Enable audio by default
      await _engine!.muteLocalAudioStream(false);
      _isAudioEnabled = true;

      // Configure channel media options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        autoSubscribeVideo: callType == CallType.video,
        publishCameraTrack: callType == CallType.video,
        publishMicrophoneTrack: true,
      );

      // Join channel with comprehensive error handling
      if (kDebugMode) {
        debugPrint('🚀 Joining channel with UID: ${tokenResponse.uid}');
      }

      await _engine!.joinChannel(
        token: tokenResponse.rtcToken,
        channelId: channelName,
        uid: tokenResponse.uid,
        options: options,
      );

      _isInCall = true;

      if (kDebugMode) {
        debugPrint('✅ Successfully initiated join for call: $channelName');
        debugPrint('   - Channel: $channelName');
        debugPrint('   - UID: ${tokenResponse.uid}');
        debugPrint('   - Call Type: ${callType.name}');
        debugPrint('   - Has Token: ${tokenResponse.rtcToken.isNotEmpty}');
      }

      // The actual join success will be confirmed in onJoinChannelSuccess callback
    } catch (e) {
      // Clean up state on failure
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      
      if (kDebugMode) {
        debugPrint('❌ Failed to join call: $e');
      }
      
      // Provide more specific error messages
      String errorMessage = 'Failed to join call: ';
      if (e.toString().contains('permissions')) {
        errorMessage += 'Microphone/camera permissions required';
      } else if (e.toString().contains('token')) {
        errorMessage += 'Authentication failed';
      } else if (e.toString().contains('network')) {
        errorMessage += 'Network connection issue';
      } else if (e.toString().contains('already in a call')) {
        errorMessage += 'Already in a call';
      } else {
        errorMessage += e.toString();
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Leave the current call
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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

  /// Renew token (public interface)
  @override
  Future<void> renewToken(String token) async {
    try {
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }

      await _engine!.renewToken(token);

      if (kDebugMode) {
        debugPrint('✅ Token renewed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to renew token: $e');
      }
      throw Exception('Failed to renew token: $e');
    }
  }

  /// Renew token when it's about to expire (internal)
  Future<void> _renewToken() async {
    try {
      if (_currentChannelName == null) return;

      final tokenResponse = await _tokenService.generateToken(
        channelName: _currentChannelName!,
        uid: _currentUid,
      );

      await _engine!.renewToken(tokenResponse.rtcToken);

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
  @override
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
        debugPrint('⚠️ Local video view creation failed: $e');
      }
      // Fallback UI with better status indication
      return Container(
        color: Colors.grey[900],
        decoration: BoxDecoration(
          border: Border.all(
            color: _isVideoEnabled ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                color: _isVideoEnabled ? Colors.green : Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _isVideoEnabled ? 'Camera Active' : 'Camera Off',
                style: TextStyle(
                  color: _isVideoEnabled ? Colors.green : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Local Video',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (_currentUid != null)
                Text(
                  'UID: $_currentUid',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  /// Create remote video view widget
  @override
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
      // Enhanced fallback UI for remote user
      final isUserConnected = _remoteUsers.contains(uid);
      return Container(
        color: Colors.grey[800],
        decoration: BoxDecoration(
          border: Border.all(
            color: isUserConnected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUserConnected ? Icons.person : Icons.person_outline,
                color: isUserConnected ? Colors.blue : Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                isUserConnected ? 'User Connected' : 'Waiting for User',
                style: TextStyle(
                  color: isUserConnected ? Colors.blue : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Remote Video',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                'UID: $uid',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              if (isUserConnected)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  /// Dispose and cleanup
  @override
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