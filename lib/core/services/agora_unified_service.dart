import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';

/// Unified cross-platform Agora service using agora_uikit 1.3.10
/// Supports Android, iOS, Web, Windows, Linux, macOS with proper video rendering
class AgoraUnifiedService implements AgoraServiceInterface {
  static final AgoraUnifiedService _instance = AgoraUnifiedService._internal();
  factory AgoraUnifiedService() => _instance;
  AgoraUnifiedService._internal();

  // Agora client
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
    try {
      if (kDebugMode) debugPrint('🚀 AgoraUnifiedService: Initializing with agora_uikit...');
      
      // Initialize Agora client - will configure when joining call
      _client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: AgoraConfig.appId,
          channelName: '', // Will be set when joining call
          tempToken: '', // Will be set when joining call
        ),
      );

      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora UIKit: $e');
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

      // For native platforms, we'll assume permissions are granted
      // The agora_uikit will handle permission requests internally
      if (kDebugMode) debugPrint('✅ AgoraUnifiedService: Permissions delegated to agora_uikit');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ AgoraUnifiedService: Permission check failed, assuming granted: $e');
      return true;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    try {
      if (_client == null) {
        throw Exception('Agora client not initialized');
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

      // Create new client with correct configuration
      _client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: AgoraConfig.appId,
          channelName: channelName,
          tempToken: token,
          uid: uid ?? 0,
        ),
      );

      // Set media options based on call type
      _isVideoEnabled = callType == CallType.video;
      _isAudioEnabled = true;

      // Initialize and join channel using agora_uikit
      await _client!.initialize();
      
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
    try {
      if (_client == null) return;

      if (kDebugMode) debugPrint('🚪 AgoraUnifiedService: Leaving call...');

      await _client!.engine.leaveChannel();
      
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
      if (_client == null) return;

      _isAudioEnabled = !_isAudioEnabled;
      await _client!.engine.muteLocalAudioStream(!_isAudioEnabled);

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
      if (_client == null) return;

      _isVideoEnabled = !_isVideoEnabled;
      await _client!.engine.muteLocalVideoStream(!_isVideoEnabled);
      await _client!.engine.enableLocalVideo(_isVideoEnabled);

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
      if (_client == null) return;

      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (!kIsWeb) {
        await _client!.engine.setEnableSpeakerphone(_isSpeakerEnabled);
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
      if (_client == null) return;

      if (!kIsWeb) {
        await _client!.engine.switchCamera();
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
      if (_client == null || _currentChannelName == null) return;

      await _client!.engine.renewToken(token);

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
  Widget createLocalVideoView() {
    if (_client == null) {
      return _buildPlaceholderView('Local Camera Not Available');
    }

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
          showNumberOfUsers: false,
        ),
      ),
    );
  }

  @override
  Widget createRemoteVideoView(int uid) {
    if (_client == null) {
      return _buildPlaceholderView('Remote Video Not Available');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AgoraVideoViewer(
          client: _client!,
          layoutType: Layout.grid,
          showNumberOfUsers: false,
        ),
      ),
    );
  }

  Widget _buildPlaceholderView(String text) {
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
              Icons.videocam_off,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

  /// Get the AgoraClient for direct access
  AgoraClient? get client => _client;

  @override
  void dispose() {
    try {
      _callEventController.close();
      _currentCallController.close();
      _client?.engine.leaveChannel();
      _client = null;
      
      if (kDebugMode) debugPrint('🧹 AgoraUnifiedService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AgoraUnifiedService: Error during dispose: $e');
    }
  }
}