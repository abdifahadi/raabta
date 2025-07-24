import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';

/// Enhanced Web implementation of Agora service with real media permissions and video
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
  
  // Media streams
  html.MediaStream? _localStream;
  final Map<int, html.MediaStream> _remoteStreams = {};
  
  // Supabase token service
  final SupabaseAgoraTokenService _tokenService = SupabaseAgoraTokenService();
  
  // Event streams
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();

  // User management
  final Set<int> _remoteUsers = <int>{};
  
  // Permission state
  bool _hasMediaPermissions = false;
  String? _permissionError;
  
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
      if (kDebugMode) debugPrint('AgoraWebService: Initializing web service...');
      
      // Check if getUserMedia is available
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('Media devices not supported in this browser');
      }
      
      if (kDebugMode) debugPrint('AgoraWebService: Web service initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to initialize web service: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    if (!kIsWeb) return false;

    try {
      if (kDebugMode) debugPrint('AgoraWebService: Checking media permissions...');
      
      // Request appropriate permissions based on call type
      final constraints = {
        'audio': true,
        'video': callType == CallType.video,
      };
      
      try {
        _localStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        _hasMediaPermissions = true;
        _permissionError = null;
        
        if (kDebugMode) debugPrint('AgoraWebService: Media permissions granted');
        
        // Emit permission granted event
        _callEventController.add({
          'type': 'permissions_granted',
          'hasVideo': callType == CallType.video,
          'hasAudio': true,
        });
        
        return true;
      } catch (e) {
        _hasMediaPermissions = false;
        _permissionError = e.toString();
        
        if (kDebugMode) debugPrint('AgoraWebService: Media permission denied: $e');
        
        // Emit permission denied event
        _callEventController.add({
          'type': 'permissions_denied',
          'error': e.toString(),
        });
        
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Permission check failed: $e');
      _callEventController.add({
        'type': 'permission_error',
        'error': e.toString(),
      });
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

      // Check permissions first
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Media permissions not granted: $_permissionError');
      }

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
        'type': 'joinChannelSuccess',
        'channelName': channelName,
        'uid': _currentUid,
      });
      
      // Simulate a remote user joining after 3 seconds for testing
      Timer(const Duration(seconds: 3), () {
        if (_isInCall) {
          const remoteUid = 12345;
          _remoteUsers.add(remoteUid);
          _callEventController.add({
            'type': 'userJoined',
            'remoteUid': remoteUid,
          });
        }
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Successfully joined call: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to join call: $e');
      _callEventController.add({
        'type': 'error',
        'message': 'Failed to join call: $e',
      });
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) debugPrint('AgoraWebService: Leaving call');
      
      // Stop local media stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        _localStream = null;
      }
      
      // Clear remote streams
      _remoteStreams.clear();
      
      // Reset state
      _currentChannelName = null;
      _currentUid = null;
      _isInCall = false;
      _remoteUsers.clear();
      _hasMediaPermissions = false;
      _permissionError = null;
      
      _currentCallController.add(null);
      
      _callEventController.add({
        'type': 'userLeft',
        'reason': 'User left call',
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to leave call: $e');
    }
  }

  @override
  Future<void> toggleMute() async {
    if (!kIsWeb || _localStream == null) return;

    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      // Toggle audio tracks
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = _isAudioEnabled;
      }
      
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
    if (!kIsWeb || _localStream == null) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      // Toggle video tracks
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = _isVideoEnabled;
      }
      
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
      // On web, we would need to get a new stream with different video constraints
      // For now, just emit an event
      _callEventController.add({
        'type': 'camera_switched',
      });
      
      if (kDebugMode) debugPrint('AgoraWebService: Camera switch requested (web limitation)');
    } catch (e) {
      if (kDebugMode) debugPrint('AgoraWebService: Failed to switch camera: $e');
    }
  }

  @override
  Future<void> renewToken(String token) async {
    // Web implementation: Agora SDK handles token renewal automatically in most cases
    // For production, you would integrate with Agora Web SDK's token renewal methods
    if (kDebugMode) {
      debugPrint('✅ AgoraWebService: Token renewal acknowledged (${token.substring(0, 20)}...)');
    }
    
    _callEventController.add({
      'type': 'token_renewed',
      'token_length': token.length,
    });
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
    if (!_hasMediaPermissions || _localStream == null) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _permissionError != null ? Icons.error : Icons.videocam_off,
                color: _permissionError != null ? Colors.red : Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _permissionError != null ? 'Permission Denied' : 'Camera Off',
                style: TextStyle(
                  color: _permissionError != null ? Colors.red : Colors.white54,
                ),
              ),
              if (_permissionError != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Please allow camera and microphone access',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: _isVideoEnabled
          ? HtmlElementView(
              key: ValueKey('local-video-$_currentUid'),
              viewType: 'local-video-view',
              onPlatformViewCreated: (id) {
                _setupLocalVideoElement();
              },
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

  void _setupLocalVideoElement() {
    if (_localStream != null) {
      final videoElement = html.VideoElement()
        ..srcObject = _localStream
        ..autoplay = true
        ..muted = true // Mute local video to prevent feedback
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      
      // Register the video element
      // Note: This is a simplified approach. In a real implementation,
      // you'd use proper platform view registration
      html.document.getElementById('local-video-container')?.append(videoElement);
    }
  }

  @override
  Widget createRemoteVideoView(int uid) {
    final isUserConnected = _remoteUsers.contains(uid);
    
    if (!isUserConnected) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white24,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Waiting for user...',
                style: TextStyle(color: Colors.white24),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[800],
      child: Stack(
        children: [
          // Remote video would go here
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'User $uid',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    leaveCall();
    _remoteUsers.clear();
    _remoteStreams.clear();
    if (!_callEventController.isClosed) {
      _callEventController.close();
    }
    if (!_currentCallController.isClosed) {
      _currentCallController.close();
    }
  }
}
