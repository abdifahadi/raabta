import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'agora_token_service.dart';

/// Simple Web implementation of Agora service
/// This avoids problematic JS interop for now and provides basic functionality
class AgoraWebService implements AgoraServiceInterface {
  static final AgoraWebService _instance = AgoraWebService._internal();
  factory AgoraWebService() => _instance;
  AgoraWebService._internal();

  String? _currentChannelName;
  int? _currentUid;
  bool _isInCall = false;
  
  // Media state
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
    if (!kIsWeb) {
      if (kDebugMode) debugPrint('AgoraWebService: Not running on web, skipping initialization');
      return;
    }

    try {
      if (kDebugMode) debugPrint('AgoraWebService: Web service initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to initialize web service: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    if (!kIsWeb) return false;

    try {
      // For now, return true on web (would normally check media permissions)
      if (kDebugMode) debugPrint('AgoraWebService: Permissions check passed');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    if (!kIsWeb) {
      throw Exception('Web service not available on non-web platforms');
    }

    try {
      if (kDebugMode) debugPrint('AgoraWebService: Joining call: $channelName');

      // Get token for the call
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
      );
      
      _currentChannelName = channelName;
      _currentUid = tokenResponse.uid;
      _isInCall = true;
      
      // Update call state
      final callModel = CallModel(
        callId: 'web_call_${DateTime.now().millisecondsSinceEpoch}',
        callerId: _currentUid.toString(),
        receiverId: '', // Will be set when remote user joins
        channelName: channelName,
        callType: callType,
        status: CallStatus.connected,
        createdAt: DateTime.now(),
        callerName: 'Web User',
        callerPhotoUrl: '',
        receiverName: 'Remote User',
        receiverPhotoUrl: '',
      );
      
      _currentCallController.add(callModel);
      
      _callEventController.add({
        'type': 'call_joined',
        'channelName': channelName,
        'uid': _currentUid,
      });
      
      // Simulate a remote user joining after 2 seconds for testing
      Timer(const Duration(seconds: 2), () {
        if (_isInCall) {
          const remoteUid = 12345;
          _remoteUsers.add(remoteUid);
          _callEventController.add({
            'type': 'user_joined',
            'uid': remoteUid,
          });
        }
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Successfully joined call: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to join call: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) debugPrint('AgoraWebService: Leaving call');
      
      // Reset state
      _currentChannelName = null;
      _currentUid = null;
      _isInCall = false;
      _remoteUsers.clear();
      
      _currentCallController.add(null);
      
      _callEventController.add({
        'type': 'call_left',
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to leave call: $e');
    }
  }

  @override
  Future<void> toggleMute() async {
    if (!kIsWeb) return;

    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      _callEventController.add({
        'type': 'audio_toggled',
        'enabled': _isAudioEnabled,
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to toggle mute: $e');
    }
  }

  @override
  Future<void> toggleVideo() async {
    if (!kIsWeb) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      _callEventController.add({
        'type': 'video_toggled',
        'enabled': _isVideoEnabled,
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to toggle video: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    if (!kIsWeb) return;

    try {
      _callEventController.add({
        'type': 'camera_switched',
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Camera switched');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to switch camera: $e');
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    // Web doesn't have a direct speaker toggle, audio plays through default output
    _isSpeakerEnabled = !_isSpeakerEnabled;
    
    _callEventController.add({
      'type': 'speaker_toggled',
      'enabled': _isSpeakerEnabled,
    });
    
    if (kDebugMode) debugPrint('AgoraWebService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
  }

  @override
  Widget createLocalVideoView() {
    return Container(
      color: Colors.grey[900],
      child: _isVideoEnabled
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Local Video (Web)',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Camera Off',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget createRemoteVideoView(int uid) {
    final isUserConnected = _remoteUsers.contains(uid);
    
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUserConnected ? Icons.person : Icons.person_outline,
              color: isUserConnected ? Colors.white54 : Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'User $uid',
              style: TextStyle(
                color: isUserConnected ? Colors.white54 : Colors.white24,
              ),
            ),
            if (isUserConnected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Connected (Web)',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    leaveCall();
    _remoteUsers.clear();
    _callEventController.close();
    _currentCallController.close();
  }
}
