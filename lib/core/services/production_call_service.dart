import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/call/domain/models/call_model.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/data/firebase_call_repository.dart';
import 'agora_service_interface.dart';
import 'agora_service_factory.dart';
import 'supabase_agora_token_service.dart';
import 'ringtone_service.dart';

import '../config/agora_config.dart';

/// Production-ready Call Service with Supabase integration
/// Handles the complete call flow from initiation to termination
class ProductionCallService {
  static final ProductionCallService _instance = ProductionCallService._internal();
  factory ProductionCallService() => _instance;
  ProductionCallService._internal();

  // Services
  final AgoraServiceInterface _agoraService = AgoraServiceFactory.getInstance();
  final SupabaseAgoraTokenService _tokenService = SupabaseAgoraTokenService();
  final CallRepository _callRepository = FirebaseCallRepository();
  late final RingtoneService _ringtoneService; 

  // Current call state
  CallModel? _currentCall;
  AgoraTokenResponse? _currentToken;
  Timer? _callTimeoutTimer;
  Timer? _tokenRefreshTimer;
  bool _isInitialized = false;

  // Stream controllers
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();
  final StreamController<Map<String, dynamic>> _callEventController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  CallModel? get currentCall => _currentCall;
  bool get isInCall => _agoraService.isInCall;
  bool get isVideoEnabled => _agoraService.isVideoEnabled;
  bool get isMuted => _agoraService.isMuted;
  bool get isSpeakerEnabled => _agoraService.isSpeakerEnabled;
  String? get currentChannelName => _currentCall?.channelName;

  // Streams
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;

  /// Initialize the production call service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        debugPrint('🚀 ProductionCallService: Initializing...');
      }

      // Initialize services
      await _agoraService.initialize();

      // Setup event forwarding
      _agoraService.callEventStream.listen(_forwardAgoraEvents);

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to initialize: $e');
      }
      throw Exception('Failed to initialize ProductionCallService: $e');
    }
  }

  /// Initialize the production call service with dependency injection
  Future<void> initializeWithDependencies(RingtoneService ringtoneService) async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        debugPrint('🚀 ProductionCallService: Initializing with dependencies...');
      }

      // Inject the ringtone service dependency
      _ringtoneService = ringtoneService;

      // Initialize services
      await _agoraService.initialize();

      // Setup event forwarding
      _agoraService.callEventStream.listen(_forwardAgoraEvents);

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Initialized successfully with dependencies');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to initialize: $e');
      }
      throw Exception('Failed to initialize ProductionCallService: $e');
    }
  }

  /// Initiate a call to another user
  Future<CallModel> initiateCall({
    required String receiverId,
    required String receiverName,
    required String receiverPhotoUrl,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String callerId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📞 ProductionCallService: Initiating call to $receiverName');
      }

      // Ensure service is initialized
      if (!_isInitialized) await initialize();

      // End any existing call first
      if (_currentCall != null) {
        await endCall(CallEndReason.newCallInitiated);
      }

      // Generate channel name
      final channelName = AgoraConfig.generateChannelName(callerId, receiverId);

      // Generate secure token via Supabase
      _currentToken = await _tokenService.generateToken(
        channelName: channelName,
        role: 'publisher',
        expirationTime: AgoraConfig.tokenExpirationTime,
      );

      // Create call model
      final call = CallModel(
        callId: AgoraConfig.generateCallId(),
        callerId: callerId,
        receiverId: receiverId,
        channelName: channelName,
        callType: callType,
        status: CallStatus.calling,
        createdAt: DateTime.now(),
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      // Store call in repository
      await _callRepository.initiateCall(call);

      _currentCall = call;
      _currentCallController.add(_currentCall);

      // Start call timeout
      _startCallTimeout();

      // Setup token refresh timer
      _setupTokenRefreshTimer();

      // Join Agora channel
      await _agoraService.joinCall(
        channelName: channelName,
        callType: callType,
        uid: _currentToken!.uid,
      );

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Call initiated successfully');
        debugPrint('🔐 Token: ${_currentToken!.rtcToken.substring(0, 20)}...');
        debugPrint('🆔 UID: ${_currentToken!.uid}');
      }

      return call;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to initiate call: $e');
      }
      await _cleanup();
      throw Exception('Failed to initiate call: $e');
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(CallModel call) async {
    try {
      if (kDebugMode) {
        debugPrint('📞 ProductionCallService: Accepting call from ${call.callerName}');
      }

      // Ensure service is initialized
      if (!_isInitialized) await initialize();

      // Stop ringtone
      await _ringtoneService.stop();

      // Generate secure token for this user
      _currentToken = await _tokenService.generateToken(
        channelName: call.channelName,
        role: 'publisher',
        expirationTime: AgoraConfig.tokenExpirationTime,
      );

      _currentCall = call;
      _currentCallController.add(_currentCall);

      // Update call status
      await _callRepository.updateCallStatus(
        call.callId,
        CallStatus.accepted,
        startedAt: DateTime.now(),
      );

      // Setup token refresh timer
      _setupTokenRefreshTimer();

      // Join Agora channel
      await _agoraService.joinCall(
        channelName: call.channelName,
        callType: call.callType,
        uid: _currentToken!.uid,
      );

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Call accepted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to accept call: $e');
      }
      await _cleanup();
      throw Exception('Failed to accept call: $e');
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    try {
      if (kDebugMode) {
        debugPrint('📞 ProductionCallService: Declining call from ${call.callerName}');
      }

      // Stop ringtone
      await _ringtoneService.stop();

      // Update call status
      await _callRepository.updateCallStatus(
        call.callId,
        CallStatus.declined,
        endedAt: DateTime.now(),
        endReason: CallEndReason.declined,
      );

      await _cleanup();

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Call declined successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to decline call: $e');
      }
    }
  }

  /// End the current call
  Future<void> endCall(CallEndReason reason) async {
    try {
      if (kDebugMode) {
        debugPrint('📞 ProductionCallService: Ending call (reason: ${reason.name})');
      }

      if (_currentCall != null) {
        final duration = DateTime.now().difference(_currentCall!.createdAt).inSeconds;

        await _callRepository.updateCallStatus(
          _currentCall!.callId,
          CallStatus.ended,
          endedAt: DateTime.now(),
          endReason: reason,
          duration: duration,
        );
      }

      // Leave Agora channel
      await _agoraService.leaveCall();

      // Stop ringtone if playing
      await _ringtoneService.stop();

      await _cleanup();

      if (kDebugMode) {
        debugPrint('✅ ProductionCallService: Call ended successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to end call: $e');
      }
      await _cleanup(); // Force cleanup even if update fails
    }
  }

  /// Toggle video during call
  Future<void> toggleVideo() async {
    await _agoraService.toggleVideo();
  }

  /// Toggle audio during call
  Future<void> toggleMute() async {
    await _agoraService.toggleMute();
  }

  /// Toggle speaker during call
  Future<void> toggleSpeaker() async {
    await _agoraService.toggleSpeaker();
  }

  /// Switch camera during call
  Future<void> switchCamera() async {
    await _agoraService.switchCamera();
  }

  /// Start call timeout timer
  void _startCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: AgoraConfig.callTimeout), () async {
      if (_currentCall?.status == CallStatus.calling) {
        if (kDebugMode) {
          debugPrint('⏰ ProductionCallService: Call timeout');
        }
        await endCall(CallEndReason.timeout);
      }
    });
  }

  /// Setup token refresh timer
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    if (_currentToken != null) {
      // Refresh token 5 minutes before expiry
      final refreshTime = Duration(seconds: _currentToken!.expirationTime - 
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 300);
      
      if (refreshTime.inSeconds > 60) { // Only setup if more than 1 minute
        _tokenRefreshTimer = Timer(refreshTime, _refreshToken);
      }
    }
  }

  /// Refresh the current token
  Future<void> _refreshToken() async {
    try {
      if (_currentCall != null && _currentToken != null) {
        if (kDebugMode) {
          debugPrint('🔄 ProductionCallService: Refreshing token...');
        }

        final newToken = await _tokenService.generateToken(
          channelName: _currentCall!.channelName,
          role: 'publisher',
          expirationTime: AgoraConfig.tokenExpirationTime,
        );

        // Update token in Agora engine
        await _agoraService.renewToken(newToken.rtcToken);
        
        _currentToken = newToken;
        _setupTokenRefreshTimer(); // Setup next refresh

        if (kDebugMode) {
          debugPrint('✅ ProductionCallService: Token refreshed successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProductionCallService: Failed to refresh token: $e');
      }
    }
  }

  /// Forward Agora events to the main event stream
  void _forwardAgoraEvents(Map<String, dynamic> event) {
    _callEventController.add(event);

    // Handle specific events
    switch (event['type']) {
      case 'userJoined':
        if (_currentCall?.status == CallStatus.calling) {
          _callRepository.updateCallStatus(
            _currentCall!.callId,
            CallStatus.connected,
            startedAt: DateTime.now(),
          );
        }
        break;
      case 'userLeft':
        if (_currentCall != null) {
          endCall(CallEndReason.remoteHangup);
        }
        break;
      case 'error':
        if (_currentCall != null) {
          endCall(CallEndReason.error);
        }
        break;
    }
  }

  /// Cleanup resources
  Future<void> _cleanup() async {
    _callTimeoutTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    _currentCall = null;
    _currentToken = null;
    _currentCallController.add(null);
    _tokenService.clearCache();
  }

  /// Dispose of the service
  void dispose() {
    _cleanup();
    _currentCallController.close();
    _callEventController.close();
  }
}