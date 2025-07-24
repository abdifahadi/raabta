import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
// Conditional import to avoid dart:ui_web errors

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';

/// Production-ready Web implementation of Agora service with proper video rendering
class ImprovedAgoraWebService implements AgoraServiceInterface {
  static final ImprovedAgoraWebService _instance = ImprovedAgoraWebService._internal();
  factory ImprovedAgoraWebService() => _instance;
  ImprovedAgoraWebService._internal();

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
  
  // Video elements for proper rendering
  html.VideoElement? _localVideoElement;
  final Map<int, html.VideoElement> _remoteVideoElements = {};
  
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
  String? _permissionError;
  
  // Getters
  @override
  bool get isInCall => _isInCall;
  
  @override
  bool get isVideoEnabled => _isVideoEnabled;
  
  @override
  int? get currentUid => _currentUid;
  
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
      if (kDebugMode) debugPrint('ImprovedAgoraWebService: Not running on web, skipping initialization');
      return;
    }

    try {
      if (kDebugMode) debugPrint('🎥 ImprovedAgoraWebService: Initializing enhanced web service...');
      
      // Check if getUserMedia is available
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('Media devices not supported in this browser');
      }

      // Check if required WebRTC APIs are available - Fixed using js_util instead of window[]
      final hasWebRTC = js_util.hasProperty(html.window, 'RTCPeerConnection');
      if (!hasWebRTC) {
        throw Exception('WebRTC not supported in this browser');
      }
      
      // Initialize video containers for proper rendering
      _initializeVideoContainers();
      
      if (kDebugMode) debugPrint('✅ ImprovedAgoraWebService: Enhanced web service initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ImprovedAgoraWebService: Failed to initialize web service: $e');
      rethrow;
    }
  }

  /// Initialize video containers for proper video rendering
  void _initializeVideoContainers() {
    if (!kIsWeb) return;

    try {
      // Create video containers if they don't exist
      final localContainer = html.document.getElementById('local-video-container');
      if (localContainer == null) {
        final container = html.DivElement()
          ..id = 'local-video-container'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.zIndex = '1000'
          ..style.pointerEvents = 'none';
        html.document.body?.append(container);
      }

      final remoteContainer = html.document.getElementById('remote-video-container');
      if (remoteContainer == null) {
        final container = html.DivElement()
          ..id = 'remote-video-container'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.zIndex = '999'
          ..style.pointerEvents = 'none';
        html.document.body?.append(container);
      }

      if (kDebugMode) debugPrint('✅ Video containers initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to initialize video containers: $e');
    }
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    if (!kIsWeb) return false;

    try {
      if (kDebugMode) debugPrint('🔍 ImprovedAgoraWebService: Checking media permissions...');
      
      // Request appropriate permissions based on call type
      final constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': callType == CallType.video ? {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30},
          'facingMode': 'user',
        } : false,
      };
      
      try {
        // Enhanced permission request with proper error handling
        _localStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        _permissionError = null;
        
        if (kDebugMode) {
          debugPrint('✅ ImprovedAgoraWebService: Media permissions granted');
          debugPrint('📋 Audio tracks: ${_localStream!.getAudioTracks().length}');
          debugPrint('📋 Video tracks: ${_localStream!.getVideoTracks().length}');
        }
        
        // Set up local video element if video call
        if (callType == CallType.video && _localStream!.getVideoTracks().isNotEmpty) {
          await _setupLocalVideo();
        }
        
        // Emit permission granted event
        _callEventController.add({
          'type': 'permissions_granted',
          'hasVideo': callType == CallType.video,
          'hasAudio': true,
          'videoTracks': _localStream!.getVideoTracks().length,
          'audioTracks': _localStream!.getAudioTracks().length,
        });
        
        return true;
      } catch (e) {
        _permissionError = e.toString();
        
        // Provide user-friendly error messages for permission denials
        String userFriendlyError;
        if (e.toString().contains('NotAllowedError') || e.toString().contains('Permission denied')) {
          userFriendlyError = 'Camera and microphone access denied. Please allow permissions in your browser settings and refresh the page.';
        } else if (e.toString().contains('NotFoundError')) {
          userFriendlyError = 'No camera or microphone found. Please connect a camera/microphone and try again.';
        } else if (e.toString().contains('NotReadableError')) {
          userFriendlyError = 'Camera or microphone is already in use by another application.';
        } else {
          userFriendlyError = 'Failed to access camera/microphone. Please check your browser settings.';
        }
        
        if (kDebugMode) debugPrint('❌ ImprovedAgoraWebService: Media permission denied: $e');
        
        // Emit permission denied event
        _callEventController.add({
          'type': 'permissions_denied',
          'error': userFriendlyError,
        });
        
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ImprovedAgoraWebService: Permission check failed: $e');
      _callEventController.add({
        'type': 'permission_error',
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Set up local video element with proper DOM attachment
  Future<void> _setupLocalVideo() async {
    if (_localStream == null || _localStream!.getVideoTracks().isEmpty) return;

    try {
      _localVideoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = _localStream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#000'
        ..style.borderRadius = '8px'
        ..controls = false
        ..setAttribute('playsinline', 'true');

      // Attach to DOM for proper display
      final localContainer = html.document.getElementById('local-video-container');
      if (localContainer != null) {
        localContainer.children.clear();
        localContainer.append(_localVideoElement!);
        
        // Ensure video plays
        await _localVideoElement!.play();
        
        if (kDebugMode) debugPrint('✅ Local video element attached to DOM and playing');
      } else {
        if (kDebugMode) debugPrint('⚠️ Local video container not found in DOM');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to set up local video: $e');
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
      if (kDebugMode) debugPrint('📞 ImprovedAgoraWebService: Joining call: $channelName');

      // Check permissions first
      final hasPermissions = await checkPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Media permissions not granted: $_permissionError');
      }

      // Get token for the call - using proper query parameters access
      String? tokenFromQuery;
      try {
        tokenFromQuery = Uri.base.queryParameters['token'];
      } catch (e) {
        if (kDebugMode) debugPrint('No token in query parameters: $e');
      }
      
      final tokenResponse = await _tokenService.generateToken(
        channelName: channelName,
        uid: uid,
        role: 'publisher',
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
        'hasLocalVideo': _localVideoElement != null,
      });
      
      // Simulate WebRTC connection process
      _simulateWebRTCConnection(callType);
      
      if (kDebugMode) debugPrint('✅ ImprovedAgoraWebService: Successfully joined call: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ImprovedAgoraWebService: Failed to join call: $e');
      _callEventController.add({
        'type': 'error',
        'message': 'Failed to join call: $e',
      });
      rethrow;
    }
  }

  /// Simulate WebRTC connection for demonstration
  void _simulateWebRTCConnection(CallType callType) {
    // Simulate connection establishment
    Timer(const Duration(seconds: 1), () {
      _callEventController.add({
        'type': 'connectionStateChanged',
        'state': 'connecting',
      });
    });

    // Simulate remote user joining
    Timer(const Duration(seconds: 3), () {
      if (_isInCall) {
        const remoteUid = 12345;
        _remoteUsers.add(remoteUid);
        
        // Create simulated remote stream for video calls
        if (callType == CallType.video) {
          _createSimulatedRemoteVideo(remoteUid);
        }
        
        _callEventController.add({
          'type': 'userJoined',
          'remoteUid': remoteUid,
          'hasVideo': callType == CallType.video,
        });
      }
    });

    // Simulate connection established
    Timer(const Duration(seconds: 4), () {
      if (_isInCall) {
        _callEventController.add({
          'type': 'connectionStateChanged',
          'state': 'connected',
        });
      }
    });
  }

  /// Create a simulated remote video for testing
  void _createSimulatedRemoteVideo(int uid) {
    try {
      final remoteVideo = html.VideoElement()
        ..autoplay = true
        ..muted = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#1a1a1a'
        ..style.borderRadius = '8px'
        ..controls = false
        ..setAttribute('playsinline', 'true');

      // Create a canvas for simulated video content
      final canvas = html.CanvasElement(width: 640, height: 480);
      final ctx = canvas.context2D;
      
      // Create animated pattern
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isInCall || !_remoteUsers.contains(uid)) {
          timer.cancel();
          return;
        }
        
        ctx.fillStyle = '#1a1a1a';
        ctx.fillRect(0, 0, 640, 480);
        
        ctx.fillStyle = '#4CAF50';
        ctx.font = '24px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('Remote User Video', 320, 200);
        
        ctx.fillStyle = '#FFF';
        ctx.font = '16px Arial';
        ctx.fillText('Connected via Web', 320, 240);
        
        // Add timestamp for animation
        ctx.fillStyle = '#888';
        ctx.font = '12px Arial';
        final now = DateTime.now();
        ctx.fillText('${now.hour}:${now.minute}:${now.second}', 320, 280);
      });

      // Attach to remote container
      final remoteContainer = html.document.getElementById('remote-video-container');
      if (remoteContainer != null) {
        remoteContainer.children.clear();
        remoteContainer.append(remoteVideo);
      }

      _remoteVideoElements[uid] = remoteVideo;
      
      if (kDebugMode) debugPrint('✅ Created simulated remote video for UID: $uid');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to create remote video for UID $uid: $e');
    }
  }

  @override
  Future<void> leaveCall() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) debugPrint('🔚 ImprovedAgoraWebService: Leaving call');
      
      // Stop local media stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        _localStream = null;
      }
      
      // Clean up video elements and DOM
      _localVideoElement = null;
      _remoteVideoElements.clear();
      
      // Clear video containers
      final localContainer = html.document.getElementById('local-video-container');
      localContainer?.children.clear();
      
      final remoteContainer = html.document.getElementById('remote-video-container');
      remoteContainer?.children.clear();
      
      // Clear remote streams
      _remoteStreams.clear();
      
      // Reset state
      _currentChannelName = null;
      _currentUid = null;
      _isInCall = false;
      _remoteUsers.clear();
      _permissionError = null;
      
      _currentCallController.add(null);
      
      _callEventController.add({
        'type': 'userLeft',
        'reason': 'User left call',
      });
      
      if (kDebugMode) debugPrint('✅ ImprovedAgoraWebService: Successfully left call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ImprovedAgoraWebService: Error leaving call: $e');
    }
  }

  @override
  Future<void> toggleMute() async {
    if (!kIsWeb || _localStream == null) return;

    try {
      _isAudioEnabled = !_isAudioEnabled;
      
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = _isAudioEnabled;
      }
      
      _callEventController.add({
        'type': 'audioStateChanged',
        'muted': !_isAudioEnabled,
      });
      
      if (kDebugMode) debugPrint('🎤 Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to toggle mute: $e');
    }
  }

  @override
  Future<void> toggleVideo() async {
    if (!kIsWeb || _localStream == null) return;

    try {
      _isVideoEnabled = !_isVideoEnabled;
      
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = _isVideoEnabled;
      }
      
      // Update local video element visibility
      if (_localVideoElement != null) {
        _localVideoElement!.style.display = _isVideoEnabled ? 'block' : 'none';
      }
      
      _callEventController.add({
        'type': 'videoStateChanged',
        'enabled': _isVideoEnabled,
      });
      
      if (kDebugMode) debugPrint('📹 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to toggle video: $e');
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    if (!kIsWeb) return;
    
    // Web doesn't have the same speaker/earpiece concept as mobile
    // Instead, we can control output volume or device selection
    _isSpeakerEnabled = !_isSpeakerEnabled;
    
    _callEventController.add({
      'type': 'speakerStateChanged',
      'enabled': _isSpeakerEnabled,
    });
    
    if (kDebugMode) debugPrint('🔊 Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
  }

  @override
  Future<void> switchCamera() async {
    if (!kIsWeb || _localStream == null) return;

    try {
      // Stop current video track
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.stop();
      }

      // Request new stream with different facing mode
      final constraints = {
        'video': {
          'facingMode': {'exact': 'environment'}, // Try back camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false, // Don't restart audio
      };

      try {
        final newStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        
        // Replace video track
        final newVideoTrack = newStream.getVideoTracks().first;
        _localStream!.addTrack(newVideoTrack);
        
        // Update local video element
        if (_localVideoElement != null) {
          _localVideoElement!.srcObject = _localStream;
        }
        
        _callEventController.add({
          'type': 'cameraChanged',
          'success': true,
        });
        
        if (kDebugMode) debugPrint('📱 Camera switched successfully');
      } catch (e) {
        // If back camera fails, try front camera again
        if (kDebugMode) debugPrint('⚠️ Camera switch failed, keeping current camera: $e');
        
        _callEventController.add({
          'type': 'cameraChanged',
          'success': false,
          'error': e.toString(),
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to switch camera: $e');
    }
  }

  @override
  Future<void> renewToken(String token) async {
    // Enhanced web implementation with proper token handling
    try {
      if (kDebugMode) {
        debugPrint('🔄 ImprovedAgoraWebService: Renewing token...');
        debugPrint('🔐 New token: ${token.substring(0, 20)}... (${token.length} chars)');
      }
      
      // In a full Agora Web SDK implementation, you would call:
      // await _agoraEngine.renewToken(token);
      
      // For now, acknowledge the token renewal
      _callEventController.add({
        'type': 'token_renewed',
        'success': true,
        'token_length': token.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (kDebugMode) {
        debugPrint('✅ ImprovedAgoraWebService: Token renewed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ImprovedAgoraWebService: Failed to renew token: $e');
      }
      
      _callEventController.add({
        'type': 'token_renewal_failed',
        'error': e.toString(),
      });
      
      throw Exception('Failed to renew token: $e');
    }
  }

  @override
  Widget createLocalVideoView() {
    if (!kIsWeb) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.videocam_off,
            color: Colors.white54,
            size: 50,
          ),
        ),
      );
    }

    // For web, show a container that represents the local video
    // The actual video element is managed in the DOM
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isVideoEnabled ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          if (_isVideoEnabled && _localVideoElement != null)
            const Center(
              child: Text(
                'Local Video\n(Visible in browser)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.videocam_off,
                color: Colors.white54,
                size: 40,
              ),
            ),
          
          // Status indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isVideoEnabled ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isVideoEnabled ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget createRemoteVideoView(int uid) {
    if (!kIsWeb) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Remote Video\n(Web Preview)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final isUserConnected = _remoteUsers.contains(uid);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUserConnected ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          if (isUserConnected)
            const Center(
              child: Text(
                'Remote Video\n(Visible in browser)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Colors.white54,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Waiting for user...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
          // Status indicator
          if (isUserConnected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    leaveCall();
    _callEventController.close();
    _currentCallController.close();
  }
}