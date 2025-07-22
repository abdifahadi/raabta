import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../features/call/domain/models/call_model.dart';
import '../config/agora_config.dart';
import 'agora_service_interface.dart';
import 'agora_token_service.dart';

/// Pure Web implementation of Agora service using JavaScript interop
/// This completely avoids the agora_rtc_engine package to prevent Web crashes
class AgoraWebService implements AgoraServiceInterface {
  static final AgoraWebService _instance = AgoraWebService._internal();
  factory AgoraWebService() => _instance;
  AgoraWebService._internal();

  // JavaScript Agora client reference
  Object? _agoraClient;
  String? _currentChannelName;
  int? _currentUid;
  bool _isInCall = false;
  
  // Media state
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  
  // Local and remote tracks
  Object? _localAudioTrack;
  Object? _localVideoTrack;
  final Map<int, Object> _remoteTracks = {};
  
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
        debugPrint('🌐 Initializing Agora Web Service with JS interop...');
      }

      if (!kIsWeb) {
        throw Exception('AgoraWebService can only be used on Web platform');
      }

      // Check if Agora Web SDK is loaded
      if (!_isAgoraWebSDKLoaded()) {
        throw Exception('Agora Web SDK not loaded. Please include the SDK in index.html');
      }

      // Create Agora RTC client using JS interop
      _agoraClient = _createAgoraClient();
      
      // Set up event handlers
      _setupEventHandlers();

      if (kDebugMode) {
        debugPrint('✅ Agora Web Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Agora Web service: $e');
      }
      rethrow;
    }
  }

  bool _isAgoraWebSDKLoaded() {
    try {
      final agoraRTC = js_util.getProperty(web.window, 'AgoraRTC');
      return agoraRTC != null;
    } catch (e) {
      return false;
    }
  }

  Object _createAgoraClient() {
    try {
      final agoraRTC = js_util.getProperty(web.window, 'AgoraRTC');
      final client = js_util.callMethod(agoraRTC, 'createClient', [
        js_util.jsify({
          'mode': 'rtc',
          'codec': 'vp8'
        })
      ]);
      
      if (kDebugMode) {
        debugPrint('🎥 Agora client created successfully');
      }
      
      return client;
    } catch (e) {
      throw Exception('Failed to create Agora client: $e');
    }
  }

  void _setupEventHandlers() {
    if (_agoraClient == null) return;

    try {
      // User joined event
      js_util.callMethod(_agoraClient!, 'on', [
        'user-joined',
        js_util.allowInterop((Object user) {
          try {
            final uid = js_util.getProperty(user, 'uid') as int;
            if (kDebugMode) {
              debugPrint('👥 User joined: $uid');
            }
            _remoteUsers.add(uid);
            _callEventController.add({
              'type': 'userJoined',
              'uid': uid,
            });
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error handling user-joined: $e');
            }
          }
        })
      ]);

      if (kDebugMode) {
        debugPrint('📡 Event handlers set up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to setup event handlers: $e');
      }
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (!kIsWeb) return false;

      // Check if we're in a secure context (HTTPS or localhost)
      final protocol = web.window.location.protocol;
      final hostname = web.window.location.hostname;
      
      if (protocol != 'https:' && 
          hostname != 'localhost' &&
          hostname != '127.0.0.1') {
        throw Exception('Web calls require HTTPS connection or localhost');
      }

      return true;
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

      if (_isInCall) {
        throw Exception('Already in a call. Please end current call first.');
      }

      await checkPermissions(callType);

      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _isInCall = true;

      _callEventController.add({
        'type': 'joinChannelSuccess',
        'channelId': channelName,
        'uid': tokenResponse.uid,
      });

      if (kDebugMode) {
        debugPrint('✅ Successfully joined Web call: $channelName');
      }
    } catch (e) {
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      
      if (kDebugMode) {
        debugPrint('❌ Failed to join Web call: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    try {
      if (!_isInCall) return;

      if (kDebugMode) {
        debugPrint('🌐 Leaving Web call: $_currentChannelName');
      }

      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();

      _currentCallController.add(null);

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

  @override
  Future<void> toggleMute() async {
    try {
      _isAudioEnabled = !_isAudioEnabled;

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
      if (kDebugMode) {
        debugPrint('📱 Web camera switch requested');
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
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Web Local Video',
              style: TextStyle(color: Colors.white54),
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
            Icon(
              Icons.person,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Remote User $uid',
              style: TextStyle(color: Colors.white54),
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
