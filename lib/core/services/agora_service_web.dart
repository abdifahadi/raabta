import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';
import '../config/agora_config.dart';
import 'agora_service_interface.dart';
import 'agora_token_service.dart';

class AgoraServiceWeb implements AgoraServiceInterface {
  static final AgoraServiceWeb _instance = AgoraServiceWeb._internal();
  factory AgoraServiceWeb() => _instance;
  AgoraServiceWeb._internal();

  String? _currentChannelName;
  int? _currentUid;
  String? _currentToken;
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

      // Initialize Web RTC for browser
      await _initializeWebRTC();

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

  Future<void> _initializeWebRTC() async {
    try {
      // Check if browser supports WebRTC
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('WebRTC not supported in this browser');
      }

      if (kDebugMode) {
        debugPrint('🌐 WebRTC supported, ready for media access');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ WebRTC initialization issue: $e');
      }
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      // Check browser media permissions
      final constraints = <String, dynamic>{
        'audio': true,
        'video': callType == CallType.video,
      };

      await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      
      if (kDebugMode) {
        debugPrint('🔐 Web permissions granted for ${callType.name}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web permissions denied: $e');
      }
      return false;
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

      // Check permissions first
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Media permissions required for calls');
      }

      // Generate token (still needed for authentication)
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _currentToken = tokenResponse.rtcToken;

      // Get user media for web
      await _getUserMedia(callType);

      _isInCall = true;

      // Simulate join event
      _callEventController.add({
        'type': 'joinChannelSuccess',
        'channelId': channelName,
        'localUid': tokenResponse.uid,
        'elapsed': 0,
      });

      if (kDebugMode) {
        debugPrint('✅ Successfully joined Web call: $channelName');
      }
    } catch (e) {
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _currentToken = null;
      
      if (kDebugMode) {
        debugPrint('❌ Failed to join Web call: $e');
      }
      throw Exception('Failed to join Web call: $e');
    }
  }

  Future<void> _getUserMedia(CallType callType) async {
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
      
      if (_localStream != null) {
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
      
      if (_localStream != null) {
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
      if (_localStream != null) {
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
            Text(
              'Web Remote Video',
              style: const TextStyle(
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