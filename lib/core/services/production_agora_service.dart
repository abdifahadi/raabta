import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Conditional import to prevent Agora from being loaded on Web
import 'package:agora_rtc_engine/agora_rtc_engine.dart' if (dart.library.html) 'web_stub.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';
import 'supabase_agora_token_service.dart';
import '../config/agora_config.dart';
import '../agora/cross_platform_video_view.dart';

/// Production-ready cross-platform Agora service using agora_rtc_engine 6.5.2
/// 
/// Features:
/// - Full cross-platform support (Android, iOS, Windows, Linux, macOS)
/// - Web platform: Calling disabled with proper fallbacks
/// - Production-grade error handling and recovery
/// - Automatic token management and renewal
/// - Optimized video rendering with fallbacks
/// - Comprehensive event handling
/// - Memory leak prevention
/// - Platform-specific optimizations
class ProductionAgoraService implements AgoraServiceInterface {
  static final ProductionAgoraService _instance = ProductionAgoraService._internal();
  factory ProductionAgoraService() => _instance;
  ProductionAgoraService._internal();

  // Core engine and state - null on Web
  RtcEngine? _engine;
  String? _currentChannelName;
  int? _currentUid;
  bool _isInCall = false;
  bool _isInitialized = false;
  
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
  
  // Token service - disabled on Web
  SupabaseAgoraTokenService? _tokenService;
  
  // Token renewal timer
  Timer? _tokenRenewalTimer;
  
  // Error recovery
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  
  // Performance monitoring
  DateTime? _callStartTime;
  final Map<String, int> _eventCounts = {};
  
  // Getters
  @override
  bool get isInCall => kIsWeb ? false : _isInCall;
  
  @override
  bool get isVideoEnabled => kIsWeb ? false : _isVideoEnabled;
  
  @override
  bool get isMuted => kIsWeb ? true : !_isAudioEnabled;
  
  @override
  bool get isSpeakerEnabled => kIsWeb ? false : _isSpeakerEnabled;
  
  @override
  String? get currentChannelName => kIsWeb ? null : _currentChannelName;
  
  @override
  int? get currentUid => kIsWeb ? null : _currentUid;
  
  @override
  Set<int> get remoteUsers => kIsWeb ? <int>{} : Set.from(_remoteUsers);
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;
  
  @override
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;

  /// Get the RTC engine for direct access - null on Web
  RtcEngine? get engine => kIsWeb ? null : _engine;

  /// Get initialization status
  bool get isInitialized => kIsWeb ? true : _isInitialized; // Always true on Web (no-op)

  @override
  Future<void> initialize() async {
    // Completely skip Agora initialization on Web platform
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 ProductionAgoraService: Web platform - Agora completely disabled');
      _isInitialized = true;
      return;
    }

    if (_isInitialized) {
      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Already initialized');
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🚀 ProductionAgoraService: Initializing with agora_rtc_engine 6.5.2...');
        debugPrint('📱 Platform: ${_getPlatformName()}');
      }
      
      // Initialize token service only on non-Web platforms
      _tokenService = SupabaseAgoraTokenService();
      
      // Create RTC engine with proper configuration
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        areaCode: AreaCode.areaCodeGlob.value(), // Global area code for best connectivity
        logConfig: LogConfig(
          level: kDebugMode ? LogLevel.logLevelInfo : LogLevel.logLevelWarn,
        ),
      ));

      // Configure platform-specific optimizations
      await _configurePlatformOptimizations();

      // Register comprehensive event handlers
      await _registerEventHandlers();

      // Enable audio and video with optimal settings
      await _configureMediaSettings();

      _isInitialized = true;
      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to initialize: $e');
      throw Exception('Failed to initialize Agora RTC Engine: $e');
    }
  }

  Future<void> _configurePlatformOptimizations() async {
    if (kIsWeb || _engine == null) return;

    try {
      // Mobile/Desktop optimizations only
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      
      // Set optimal video encoder configuration
      await _engine!.setVideoEncoderConfiguration(VideoEncoderConfiguration(
        dimensions: VideoDimensions(
          width: AgoraConfig.videoWidth,
          height: AgoraConfig.videoHeight,
        ),
        frameRate: AgoraConfig.videoFrameRate,
        bitrate: AgoraConfig.videoBitrate,
        orientationMode: OrientationMode.orientationModeAdaptive,
        degradationPreference: DegradationPreference.maintainQuality,
      ));

      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Platform optimizations applied');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ProductionAgoraService: Platform optimization failed: $e');
      // Continue without optimizations
    }
  }

  Future<void> _registerEventHandlers() async {
    if (kIsWeb || _engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _incrementEventCount('channelJoined');
        _callStartTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('✅ ProductionAgoraService: Successfully joined channel: ${connection.channelId}');
          debugPrint('   UID: ${connection.localUid}, Elapsed: ${elapsed}ms');
        }
        _callEventController.add({
          'type': 'channelJoined',
          'channelId': connection.channelId,
          'uid': connection.localUid,
          'elapsed': elapsed,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _incrementEventCount('userJoined');
        _remoteUsers.add(remoteUid);
        if (kDebugMode) {
          debugPrint('👥 ProductionAgoraService: User joined - UID: $remoteUid');
        }
        _callEventController.add({
          'type': 'userJoined',
          'uid': remoteUid,
          'elapsed': elapsed,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        _incrementEventCount('userOffline');
        _remoteUsers.remove(remoteUid);
        if (kDebugMode) {
          debugPrint('👋 ProductionAgoraService: User offline - UID: $remoteUid, Reason: $reason');
        }
        _callEventController.add({
          'type': 'userOffline',
          'uid': remoteUid,
          'reason': reason.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        _incrementEventCount('tokenWillExpire');
        if (kDebugMode) debugPrint('🔑 ProductionAgoraService: Token will expire soon');
        _handleTokenRenewal();
        _callEventController.add({
          'type': 'tokenWillExpire',
          'token': token,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onError: (ErrorCodeType err, String msg) {
        _incrementEventCount('error');
        if (kDebugMode) {
          debugPrint('❌ ProductionAgoraService: Error occurred - Code: $err, Message: $msg');
        }
        _handleError(err, msg);
        _callEventController.add({
          'type': 'error',
          'errorCode': err.toString(),
          'message': msg,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        _incrementEventCount('connectionStateChanged');
        if (kDebugMode) {
          debugPrint('🔗 ProductionAgoraService: Connection state changed - State: $state, Reason: $reason');
        }
        _handleConnectionStateChange(state, reason);
        _callEventController.add({
          'type': 'connectionStateChanged',
          'state': state.toString(),
          'reason': reason.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        _incrementEventCount('remoteVideoStateChanged');
        if (kDebugMode) {
          debugPrint('📹 ProductionAgoraService: Remote video state changed - UID: $remoteUid, State: $state');
        }
        _callEventController.add({
          'type': 'remoteVideoStateChanged',
          'uid': remoteUid,
          'state': state.toString(),
          'reason': reason.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
        _incrementEventCount('remoteAudioStateChanged');
        if (kDebugMode) {
          debugPrint('🎤 ProductionAgoraService: Remote audio state changed - UID: $remoteUid, State: $state');
        }
        _callEventController.add({
          'type': 'remoteAudioStateChanged',
          'uid': remoteUid,
          'state': state.toString(),
          'reason': reason.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onNetworkQuality: (RtcConnection connection, int remoteUid, QualityType txQuality, QualityType rxQuality) {
        // Only log poor quality to avoid spam
        if (txQuality == QualityType.qualityPoor || rxQuality == QualityType.qualityPoor) {
          if (kDebugMode) {
            debugPrint('📡 ProductionAgoraService: Poor network quality - UID: $remoteUid, TX: $txQuality, RX: $rxQuality');
          }
        }
        _callEventController.add({
          'type': 'networkQuality',
          'uid': remoteUid,
          'txQuality': txQuality.toString(),
          'rxQuality': rxQuality.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
    ));
  }

  Future<void> _configureMediaSettings() async {
    if (kIsWeb || _engine == null) return;

    try {
      // Enable audio with optimal settings
      await _engine!.enableAudio();
      await _engine!.setDefaultAudioRouteToSpeakerphone(false);
      
      // Enable video with optimal settings
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      
      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Media settings configured');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ProductionAgoraService: Media configuration failed: $e');
    }
  }

  void _incrementEventCount(String eventType) {
    _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;
  }

  void _handleError(ErrorCodeType errorCode, String message) {
    // Handle specific error types
    switch (errorCode) {
      case ErrorCodeType.errTokenExpired:
        _handleTokenRenewal();
        break;
      case ErrorCodeType.errNetDown:
      case ErrorCodeType.errFailed:
        _handleNetworkError();
        break;
      default:
        // Log the error but continue
        break;
    }
  }

  void _handleConnectionStateChange(ConnectionStateType state, ConnectionChangedReasonType reason) {
    switch (state) {
      case ConnectionStateType.connectionStateDisconnected:
        if (reason == ConnectionChangedReasonType.connectionChangedInterrupted) {
          _handleNetworkError();
        }
        break;
      case ConnectionStateType.connectionStateReconnecting:
        _reconnectAttempts++;
        if (kDebugMode) debugPrint('🔄 ProductionAgoraService: Reconnecting... Attempt: $_reconnectAttempts');
        break;
      case ConnectionStateType.connectionStateConnected:
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        if (kDebugMode) debugPrint('✅ ProductionAgoraService: Connection restored');
        break;
      default:
        break;
    }
  }

  void _handleNetworkError() {
    if (kIsWeb) return; // No network error handling on Web

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: 2 * _reconnectAttempts + 1), () {
        if (_isInCall && _currentChannelName != null) {
          if (kDebugMode) debugPrint('🔄 ProductionAgoraService: Attempting to reconnect...');
          // The SDK will handle reconnection automatically
        }
      });
    }
  }

  void _handleTokenRenewal() {
    if (kIsWeb) return; // No token renewal on Web

    if (_currentChannelName == null || _currentUid == null) return;
    
    _tokenRenewalTimer?.cancel();
    _tokenRenewalTimer = Timer(const Duration(seconds: 5), () async {
      try {
        final newToken = await _tokenService!.getToken(
          channelName: _currentChannelName!,
          uid: _currentUid!,
          callType: _isVideoEnabled ? CallType.video : CallType.audio,
        );
        await renewToken(newToken);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ ProductionAgoraService: Token renewal failed: $e');
      }
    });
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    try {
      if (kIsWeb) {
        // On web, permissions are handled by the browser automatically
        if (kDebugMode) debugPrint('🌐 ProductionAgoraService: Web permissions handled by browser');
        return true;
      }

      List<Permission> permissions = [Permission.microphone];
      if (callType == CallType.video) {
        permissions.add(Permission.camera);
      }

      final statuses = await permissions.request();
      
      bool allGranted = true;
      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          allGranted = false;
          if (kDebugMode) debugPrint('⚠️ ProductionAgoraService: Permission denied for $permission');
        }
      }

      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Permissions check result: $allGranted');
      return allGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 ProductionAgoraService: joinCall disabled on Web platform');
      throw UnsupportedError('Video calling is not supported on Web platform. Please use the mobile or desktop app.');
    }

    try {
      if (!_isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }

      if (_engine == null) {
        throw Exception('Agora engine not available');
      }

      if (kDebugMode) {
        debugPrint('📞 ProductionAgoraService: Joining ${callType.name} call');
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
      final token = await _tokenService!.getToken(
        channelName: channelName,
        uid: uid ?? 0,
        callType: callType,
      );

      // Set media options based on call type
      _isVideoEnabled = callType == CallType.video;
      _isAudioEnabled = true;

      // Set channel media options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: _isVideoEnabled,
        publishMicrophoneTrack: _isAudioEnabled,
        publishScreenTrack: false,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      );

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid ?? 0,
        options: options,
      );
      
      // Update state
      _currentChannelName = channelName;
      _currentUid = uid ?? 0;
      _isInCall = true;
      _reconnectAttempts = 0;

      // Start token renewal timer (renew every 50 minutes)
      _tokenRenewalTimer = Timer.periodic(
        const Duration(minutes: 50),
        (_) => _handleTokenRenewal(),
      );

      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Successfully joined ${callType.name} call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to join call: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveCall() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 ProductionAgoraService: leaveCall - nothing to do on Web platform');
      return;
    }

    try {
      if (_engine == null) return;

      if (kDebugMode) debugPrint('🚪 ProductionAgoraService: Leaving call...');

      // Cancel timers
      _tokenRenewalTimer?.cancel();
      _reconnectTimer?.cancel();

      // Leave channel
      await _engine!.leaveChannel();
      
      // Reset state
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();
      _reconnectAttempts = 0;
      _callStartTime = null;

      if (kDebugMode) {
        debugPrint('✅ ProductionAgoraService: Successfully left call');
        debugPrint('📊 Event statistics: $_eventCounts');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to leave call: $e');
      // Don't rethrow here to ensure cleanup happens
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      if (_engine == null) return;

      _isAudioEnabled = !_isAudioEnabled;
      await _engine!.muteLocalAudioStream(!_isAudioEnabled);

      _callEventController.add({
        'type': 'audioToggled',
        'enabled': _isAudioEnabled,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('🎤 ProductionAgoraService: Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to toggle mute: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleVideo() async {
    try {
      if (_engine == null) return;

      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      await _engine!.enableLocalVideo(_isVideoEnabled);

      _callEventController.add({
        'type': 'videoToggled',
        'enabled': _isVideoEnabled,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('📹 ProductionAgoraService: Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to toggle video: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleSpeaker() async {
    try {
      if (_engine == null) return;

      _isSpeakerEnabled = !_isSpeakerEnabled;
      
      if (!kIsWeb) {
        await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
      }

      _callEventController.add({
        'type': 'speakerToggled',
        'enabled': _isSpeakerEnabled,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('🔊 ProductionAgoraService: Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to toggle speaker: $e');
      rethrow;
    }
  }

  @override
  Future<void> switchCamera() async {
    try {
      if (_engine == null) return;

      if (!kIsWeb) {
        await _engine!.switchCamera();
      }

      _callEventController.add({
        'type': 'cameraSwitched',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) debugPrint('🔄 ProductionAgoraService: Camera switched');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to switch camera: $e');
      rethrow;
    }
  }

  @override
  Future<void> renewToken(String token) async {
    try {
      if (kIsWeb || _currentChannelName == null) return;

      await _engine!.renewToken(token);

      _callEventController.add({
        'type': 'tokenRenewed',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) debugPrint('🔑 ProductionAgoraService: Token renewed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Failed to renew token: $e');
      rethrow;
    }
  }

  @override
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    if (kIsWeb || !_isInitialized || _engine == null) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Local Camera Not Available',
        icon: Icons.videocam_off,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return CrossPlatformVideoViewFactory.createLocalVideoView(
      engine: _engine!,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget createRemoteVideoView(int uid, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    if (kIsWeb || !_isInitialized || _engine == null) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Remote Video Not Available',
        icon: Icons.person,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return CrossPlatformVideoViewFactory.createRemoteVideoView(
      engine: _engine!,
      uid: uid,
      channelId: _currentChannelName,
      width: width,
      height: height,
      borderRadius: borderRadius,
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

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'callDuration': _callStartTime != null 
          ? DateTime.now().difference(_callStartTime!).inSeconds 
          : 0,
      'eventCounts': Map.from(_eventCounts),
      'remoteUserCount': _remoteUsers.length,
      'reconnectAttempts': _reconnectAttempts,
      'isInitialized': _isInitialized,
      'platform': _getPlatformName(),
    };
  }

  @override
  void dispose() {
    try {
      if (kDebugMode) debugPrint('🧹 ProductionAgoraService: Disposing...');
      
      // Cancel all timers
      _tokenRenewalTimer?.cancel();
      _reconnectTimer?.cancel();
      
      // Close streams
      _callEventController.close();
      _currentCallController.close();
      
      // Leave channel and release engine
      _engine?.leaveChannel();
      _engine?.release();
      _engine = null;
      
      // Reset state
      _isInitialized = false;
      _isInCall = false;
      _currentChannelName = null;
      _currentUid = null;
      _remoteUsers.clear();
      _eventCounts.clear();
      _reconnectAttempts = 0;
      _callStartTime = null;
      
      if (kDebugMode) debugPrint('✅ ProductionAgoraService: Disposed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ProductionAgoraService: Error during dispose: $e');
    }
  }
}