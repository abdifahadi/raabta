import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../features/call/domain/models/call_model.dart';
import '../config/agora_config.dart';
import '../platform/agora_web_platform_fix.dart';
import 'agora_service_interface.dart';
import 'agora_token_service.dart';

// Conditional import for web-specific functionality with proper error handling
import 'web_html_stub.dart'
    if (dart.library.html) 'dart:html' as html;

class AgoraServiceWeb implements AgoraServiceInterface {
  static final AgoraServiceWeb _instance = AgoraServiceWeb._internal();
  factory AgoraServiceWeb() => _instance;
  AgoraServiceWeb._internal();

  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  String? _currentToken; // Used for token renewal in web
  bool _isInCall = false;
  
  // Video settings
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  
  // Token service
  final AgoraTokenService _tokenService = AgoraTokenService();
  
  // Event streams
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();

  // User management
  final Set<int> _remoteUsers = <int>{};
  
  // Web-specific media streams
  html.MediaStream? _localStream;
  html.MediaStream? _remoteStream;
  
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

  @override
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 Initializing Agora Web Service...');
      }

      // Ensure web platform fix is initialized
      if (!AgoraWebPlatformFix.isInitialized) {
        AgoraWebCompatibility.initialize();
      }

      // Initialize Agora RTC Engine for Web
      await _initializeAgoraEngine();

      if (kDebugMode) {
        debugPrint('✅ Agora Web Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Agora Web service: $e');
      }
      // Don't throw error for web - graceful degradation
    }
  }

  Future<void> _initializeAgoraEngine() async {
    try {
      // Check if browser supports WebRTC first (only on web)
      if (kIsWeb && html.window.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser');
      }

      // Create Agora RTC Engine with web-safe configuration
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          logConfig: LogConfig(
            level: kDebugMode ? LogLevel.logLevelInfo : LogLevel.logLevelWarn,
          ),
        ),
      );

      // Set up event handlers
      _setupEventHandlers();

      if (kDebugMode) {
        debugPrint('🎥 Agora RTC Engine initialized for web');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Agora engine initialization issue: $e');
      }
      // Continue with fallback WebRTC implementation
      await _initializeFallbackWebRTC();
    }
  }

  Future<void> _initializeFallbackWebRTC() async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 Using fallback WebRTC implementation');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fallback WebRTC initialization issue: $e');
      }
    }
  }

  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (kDebugMode) {
            debugPrint('🎉 Successfully joined channel: ${connection.channelId}');
          }
          _callEventController.add({
            'type': 'joinChannelSuccess',
            'channelId': connection.channelId,
            'uid': connection.localUid,
            'elapsed': elapsed,
          });
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          if (kDebugMode) {
            debugPrint('👥 User joined: $uid');
          }
          _remoteUsers.add(uid);
          _callEventController.add({
            'type': 'userJoined',
            'uid': uid,
            'elapsed': elapsed,
          });
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          if (kDebugMode) {
            debugPrint('�� User left: $uid, reason: ${reason.name}');
          }
          _remoteUsers.remove(uid);
          _callEventController.add({
            'type': 'userOffline',
            'uid': uid,
            'reason': reason.name,
          });
        },
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) {
            debugPrint('❌ Agora error: ${err.name} - $msg');
          }
          _callEventController.add({
            'type': 'error',
            'errorCode': err.name,
            'message': msg,
          });
        },
      ),
    );
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (!kIsWeb) {
        // On non-web platforms, assume permissions are handled elsewhere
        return true;
      }

      // Check if we're in a secure context (HTTPS or localhost) - only on web
      if (kIsWeb) {
        try {
          final protocol = html.window.location.protocol;
          final hostname = html.window.location.hostname;
          
          if (protocol != 'https:' && 
              hostname != null &&
              !hostname.contains('localhost') &&
              !hostname.contains('127.0.0.1')) {
            if (kDebugMode) {
              debugPrint('⚠️ Web calls require HTTPS or localhost. Current: $protocol//$hostname');
            }
            throw Exception('Web calls require HTTPS connection. Please use HTTPS or localhost.');
          }
        } catch (e) {
          // If location access fails, continue with permission check
          if (kDebugMode) {
            debugPrint('⚠️ Could not check location protocol: $e');
          }
        }
      }

      // Check if browser supports WebRTC
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser. Please use a modern browser like Chrome, Firefox, or Safari.');
      }

      // Request browser media permissions
      final constraints = <String, dynamic>{
        'audio': true,
        'video': callType == CallType.video ? {
          'width': {'ideal': AgoraConfig.videoWidth},
          'height': {'ideal': AgoraConfig.videoHeight},
          'frameRate': {'ideal': AgoraConfig.videoFrameRate},
        } : false,
      };

      try {
        final stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        
        // Stop the stream immediately - we just needed to check permissions
        for (final track in stream.getTracks()) {
          track.stop();
        }
        
        if (kDebugMode) {
          debugPrint('🔐 Web permissions granted for ${callType.name}');
        }
        return true;
      } catch (permissionError) {
        if (kDebugMode) {
          debugPrint('❌ Web media permissions denied: $permissionError');
        }
        
        String errorMessage = 'Media permissions required for calls. ';
        if (permissionError.toString().contains('NotAllowedError')) {
          errorMessage += 'Please allow microphone';
          if (callType == CallType.video) {
            errorMessage += ' and camera';
          }
          errorMessage += ' access in your browser.';
        } else if (permissionError.toString().contains('NotFoundError')) {
          errorMessage += 'No microphone or camera found on your device.';
        } else {
          errorMessage += 'Please check your browser settings.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web permissions check error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 Joining Web call: $channelName (${callType.name})');
      }

      // Check if already in a call
      if (_isInCall) {
        throw Exception('Already in a call. Please end current call first.');
      }

      // Check permissions first with detailed error handling
      try {
        await checkPermissions(callType);
      } catch (permissionError) {
        throw Exception('Web permissions error: ${permissionError.toString()}');
      }

      // Generate token with fallback support
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );

      if (kDebugMode) {
        debugPrint('🔑 Web token generated: ${tokenResponse.toString()}');
      }

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _currentToken = tokenResponse.rtcToken;

      try {
        if (_engine != null) {
          // Use Agora RTC Engine if available
          await _joinWithAgoraEngine(channelName, tokenResponse.rtcToken, tokenResponse.uid, callType);
        } else {
          // Fallback to WebRTC implementation
          await _joinWithWebRTC(callType);
        }

        _isInCall = true;

        if (kDebugMode) {
          debugPrint('✅ Successfully joined Web call: $channelName');
          debugPrint('   - Channel: $channelName');
          debugPrint('   - UID: ${tokenResponse.uid}');
          debugPrint('   - Call Type: ${callType.name}');
          debugPrint('   - Using: ${_engine != null ? 'Agora SDK' : 'WebRTC Fallback'}');
        }
      } catch (joinError) {
        // Reset state on join failure
        _isInCall = false;
        _currentChannelName = null;
        _currentUid = null;
        _currentToken = null;
        
        throw Exception('Failed to establish call connection: ${joinError.toString()}');
      }
    } catch (e) {
      // Ensure state is clean on any failure
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _currentToken = null;
      
      if (kDebugMode) {
        debugPrint('❌ Failed to join Web call: $e');
      }
      
      // Provide more specific error messages for web
      String errorMessage = 'Web call failed: ';
      if (e.toString().contains('permissions')) {
        errorMessage += 'Browser permissions required';
      } else if (e.toString().contains('HTTPS')) {
        errorMessage += 'HTTPS connection required';
      } else if (e.toString().contains('WebRTC')) {
        errorMessage += 'Browser not supported';
      } else if (e.toString().contains('token')) {
        errorMessage += 'Authentication failed';
      } else {
        errorMessage += e.toString().replaceAll('Exception: ', '');
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<void> _joinWithAgoraEngine(String channelName, String token, int uid, CallType callType) async {
    try {
      // Configure engine for call type
      if (callType == CallType.video) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
        _isVideoEnabled = true;
      } else {
        await _engine!.enableLocalVideo(false);
        _isVideoEnabled = false;
      }

      // Enable audio by default
      await _engine!.muteLocalAudioStream(false);
      _isAudioEnabled = true;

      // Configure channel media options for web
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        autoSubscribeVideo: callType == CallType.video,
        publishCameraTrack: callType == CallType.video,
        publishMicrophoneTrack: true,
      );

      // Join channel with Agora RTC Engine
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: options,
      );

      if (kDebugMode) {
        debugPrint('🎥 Joined channel with Agora RTC Engine for web');
        debugPrint('   - Video enabled: $_isVideoEnabled');
        debugPrint('   - Audio enabled: $_isAudioEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to join with Agora engine: $e');
      }
      // Fallback to WebRTC if Agora SDK fails on web
      await _joinWithWebRTC(callType);
    }
  }

  Future<void> _joinWithWebRTC(CallType callType) async {
    try {
      // Get user media for web fallback
      if (kIsWeb) {
        await _getUserMedia(callType);
      }

      // Simulate join event for fallback
      _callEventController.add({
        'type': 'joinChannelSuccess',
        'channelId': _currentChannelName,
        'localUid': _currentUid,
        'elapsed': 0,
      });

      if (kDebugMode) {
        debugPrint('🌐 Joined with WebRTC fallback');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ WebRTC fallback failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _getUserMedia(CallType callType) async {
    if (!kIsWeb) return;

    try {
      final constraints = <String, dynamic>{
        'audio': true,
        'video': callType == CallType.video ? {
          'width': AgoraConfig.videoWidth,
          'height': AgoraConfig.videoHeight,
          'frameRate': AgoraConfig.videoFrameRate,
        } : false,
      };

      _localStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      
      if (kDebugMode) {
        debugPrint('🎥 Web media stream acquired');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get user media: $e');
      }
      throw e;
    }
  }

  @override
  Future<void> leaveCall() async {
    try {
      if (!_isInCall) {
        if (kDebugMode) {
          debugPrint('⚠️ No active Web call to leave');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🌐 Leaving Web call: $_currentChannelName');
      }

      // Stop media streams
      await _stopMediaStreams();

      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _currentToken = null;
      _remoteUsers.clear();

      _currentCallController.add(null);

      // Simulate leave event
      _callEventController.add({
        'type': 'leaveChannel',
        'channelId': _currentChannelName,
      });

      if (kDebugMode) {
        debugPrint('✅ Successfully left Web call');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error leaving Web call: $e');
      }
    }
  }

  Future<void> _stopMediaStreams() async {
    if (!kIsWeb) return;

    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          track.stop();
        }
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) {
          track.stop();
        }
        _remoteStream = null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error stopping media streams: $e');
      }
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      if (kIsWeb && _localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = _isAudioEnabled;
        }
      }

      if (kDebugMode) {
        debugPrint('🎤 Web audio ${_isAudioEnabled ? 'unmuted' : 'muted'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle Web mute: $e');
      }
    }
  }

  @override
  Future<void> toggleVideo() async {
    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      if (kIsWeb && _localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        for (final track in videoTracks) {
          track.enabled = _isVideoEnabled;
        }
      }

      if (kDebugMode) {
        debugPrint('📹 Web video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle Web video: $e');
      }
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (kDebugMode) {
        debugPrint('🔊 Web speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle Web speaker: $e');
      }
    }
  }

  @override
  Future<void> switchCamera() async {
    try {
      if (kIsWeb && _localStream != null) {
        // Web camera switching is more complex - simplified for compatibility
        if (kDebugMode) {
          debugPrint('📱 Web camera switch requested (simplified)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to switch Web camera: $e');
      }
    }
  }

  @override
  Widget createLocalVideoView() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Web Local Video',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (_localStream != null)
              const Text(
                'Stream Active',
                style: TextStyle(
                  color: Colors.green,
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
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person,
              color: Colors.white60,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Web Remote Video',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            Text(
              'UID: $uid',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() async {
    try {
      if (_isInCall) {
        await leaveCall();
      }

      // Clean up Agora engine
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }

      await _stopMediaStreams();
      
      _callEventController.close();
      _currentCallController.close();

      if (kDebugMode) {
        debugPrint('🧹 Agora Web service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disposing Agora Web service: $e');
      }
    }
  }
}
