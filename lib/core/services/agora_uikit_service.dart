import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';

/// Cross-platform Agora service implementation using agora_uikit
/// Supports Web, Android, iOS, Windows, macOS, and Linux
class AgoraUIKitService implements AgoraServiceInterface {
  static final AgoraUIKitService _instance = AgoraUIKitService._internal();
  factory AgoraUIKitService() => _instance;
  AgoraUIKitService._internal();

  AgoraClient? _client;
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
      
      // AgoraUIKit handles platform-specific initialization internally
      // No explicit initialization needed as it's done when creating AgoraClient
      
      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora UIKit service: $e');
    }
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

      // Create AgoraClient with connection data
      _client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: AgoraConfig.appId,
          channelName: channelName,
          tempToken: tokenResponse.rtcToken,
          uid: tokenResponse.uid,
        ),
      );

      // Initialize the client
      await _client!.initialize();

      // Set up event listeners
      _setupEventListeners();

      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _isInCall = true;

      // Enable/disable video based on call type
      if (callType == CallType.video) {
        _isVideoEnabled = true;
      } else {
        _isVideoEnabled = false;
        // Disable video for audio-only calls
        await toggleVideo();
      }

      if (kDebugMode) {
        debugPrint('✅ AgoraUIKitService: Successfully joined call');
        debugPrint('🆔 UID: ${tokenResponse.uid}');
        debugPrint('🔐 Token: ${tokenResponse.rtcToken.substring(0, 20)}...');
      }

      _callEventController.add({
        'type': 'joinChannelSuccess',
        'channel': channelName,
        'uid': tokenResponse.uid,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to join call: $e');
      throw Exception('Failed to join call: $e');
    }
  }

  void _setupEventListeners() {
    if (_client == null) return;

    // Listen to user join events
    _client!.sessionController.value.users.addListener(() {
      final currentUsers = _client!.sessionController.value.users.value;
      final newUsers = currentUsers.where((uid) => !_remoteUsers.contains(uid)).toSet();
      final leftUsers = _remoteUsers.where((uid) => !currentUsers.contains(uid)).toSet();

      // Handle new users
      for (final uid in newUsers) {
        _remoteUsers.add(uid);
        _callEventController.add({
          'type': 'userJoined',
          'uid': uid,
        });
        if (kDebugMode) debugPrint('AgoraUIKitService: User joined: $uid');
      }

      // Handle users who left
      for (final uid in leftUsers) {
        _remoteUsers.remove(uid);
        _callEventController.add({
          'type': 'userLeft',
          'uid': uid,
          'reason': 'UserOffline',
        });
        if (kDebugMode) debugPrint('AgoraUIKitService: User left: $uid');
      }
    });

    // Listen to connection state changes
    _client!.sessionController.value.connectionData.addListener(() {
      final connectionData = _client!.sessionController.value.connectionData.value;
      _callEventController.add({
        'type': 'connectionStateChanged',
        'state': connectionData.toString(),
      });
    });
  }

  @override
  Future<void> leaveCall() async {
    if (_client == null) return;

    try {
      if (kDebugMode) debugPrint('AgoraUIKitService: Leaving call...');
      
      // Dispose the client
      await _client!.release();
      _client = null;
      
      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();
      
      _callEventController.add({
        'type': 'leaveChannel',
      });
      
      if (kDebugMode) debugPrint('✅ AgoraUIKitService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Failed to leave call: $e');
      throw Exception('Failed to leave call: $e');
    }
  }

  @override
  Future<void> toggleMute() async {
    if (_client == null) return;

    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      // UIKit handles audio state through the engine
      final engine = _client!.sessionController.value.engine;
      if (engine != null) {
        await engine.muteLocalAudioStream(!_isAudioEnabled);
      }
      
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
    if (_client == null) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      // UIKit handles video state through the engine
      final engine = _client!.sessionController.value.engine;
      if (engine != null) {
        await engine.muteLocalVideoStream(!_isVideoEnabled);
        await engine.enableLocalVideo(_isVideoEnabled);
      }
      
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
    if (_client == null) return;

    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      // UIKit handles speaker state through the engine
      final engine = _client!.sessionController.value.engine;
      if (engine != null && !kIsWeb) {
        // Speaker toggle not applicable on web
        await engine.setEnableSpeakerphone(_isSpeakerEnabled);
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
    if (_client == null) return;

    try {
      // UIKit handles camera switching through the engine
      final engine = _client!.sessionController.value.engine;
      if (engine != null && !kIsWeb) {
        // Camera switching not applicable on web in the same way
        await engine.switchCamera();
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
    if (_client == null || _currentChannelName == null) return;

    try {
      // UIKit handles token renewal through the engine
      final engine = _client!.sessionController.value.engine;
      if (engine != null) {
        await engine.renewToken(token);
      }
      
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
    if (_client == null) {
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

    // Use AgoraVideoViewer from UIKit which handles all platforms including web
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AgoraVideoViewer(
          client: _client!,
          layoutType: Layout.oneToOne,
          enableHostControls: false,
          showNumberOfUsers: false,
          showMicStatus: false,
          showAVState: false,
        ),
      ),
    );
  }

  @override
  Widget createRemoteVideoView(int uid) {
    if (_client == null) {
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

    // AgoraVideoViewer automatically handles remote video rendering
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AgoraVideoViewer(
          client: _client!,
          layoutType: Layout.floating,
          enableHostControls: false,
          showNumberOfUsers: false,
          showMicStatus: false,
          showAVState: false,
        ),
      ),
    );
  }

  /// Get the AgoraClient for direct UIKit usage
  AgoraClient? get client => _client;

  @override
  void dispose() {
    try {
      _callEventController.close();
      _currentCallController.close();
      _client?.release();
      _client = null;
      
      if (kDebugMode) debugPrint('🧹 AgoraUIKitService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUIKitService: Error during dispose: $e');
    }
  }
}