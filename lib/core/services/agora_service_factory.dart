import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../agora/agora_service.dart';
import '../agora/cross_platform_video_view.dart';
import 'agora_service_interface.dart';
import 'production_agora_service.dart';
import '../../features/call/domain/models/call_model.dart';

/// Factory for creating Agora service instances
/// Uses ProductionAgoraService with Web platform calling completely disabled
class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Create a new service instance
  AgoraServiceInterface createService() {
    return ProductionAgoraService();
  }
  
  /// Get the unified AgoraService implementation for all platforms
  /// Uses ProductionAgoraService with Web calling disabled
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    // Use the production AgoraService for all platforms
    // Web platform will have calling disabled within the service
    _instance = ProductionAgoraService();
    
    return _instance!;
  }
  
  /// Get the raw AgoraService instance (legacy support)
  static AgoraService getNewService() {
    return AgoraService();
  }
  
  /// Reset the instance (useful for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  /// Check if current platform supports Agora natively
  /// Returns false for Web platform where calling is disabled
  static bool get isNativeSupported => !kIsWeb;
  
  /// Check if current platform is web
  static bool get isWebPlatform => kIsWeb;
}

/// Adapter to make the new AgoraService compatible with the existing interface
/// Web platform functionality is disabled at the service level
class AgoraUnifiedServiceAdapter implements AgoraServiceInterface {
  final AgoraService _agoraService = AgoraService();
  
  @override
  bool get isInCall => kIsWeb ? false : _agoraService.isInCall;
  
  @override
  bool get isVideoEnabled => kIsWeb ? false : _agoraService.isVideoEnabled;
  
  @override
  bool get isMuted => kIsWeb ? true : _agoraService.isMuted;
  
  @override
  bool get isSpeakerEnabled => kIsWeb ? false : _agoraService.isSpeakerEnabled;
  
  @override
  String? get currentChannelName => kIsWeb ? null : _agoraService.currentChannelName;
  
  @override
  int? get currentUid => kIsWeb ? null : _agoraService.currentUid;
  
  @override
  Set<int> get remoteUsers => kIsWeb ? <int>{} : _agoraService.remoteUsers;
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => _agoraService.callEventStream;
  
  @override
  Stream<CallModel?> get currentCallStream => _agoraService.currentCallStream;
  
  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - initialization skipped');
      return;
    }
    await _agoraService.initializeEngine('4bfa94cebfb04852951bfdf9858dbc4b'); // Using the appId from AgoraConfig
  }
  
  @override
  Future<bool> checkPermissions(CallType callType) async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - permissions not required');
      return false; // Always false on Web since calling is disabled
    }
    return await _agoraService.checkPermissions(callType);
  }
  
  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Video calling is not supported on Web platform. Please use the mobile or desktop app.');
    }
    // Get token from the service
    final token = ''; // Will be handled internally by the service
    await _agoraService.joinChannel(token, channelName, uid ?? 0);
  }
  
  @override
  Future<void> leaveCall() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - leaveCall is no-op');
      return;
    }
    await _agoraService.leaveChannel();
  }
  
  @override
  Future<void> toggleMute() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - toggleMute is no-op');
      return;
    }
    await _agoraService.toggleMute();
  }
  
  @override
  Future<void> toggleVideo() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - toggleVideo is no-op');
      return;
    }
    await _agoraService.toggleVideo();
  }
  
  @override
  Future<void> toggleSpeaker() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - toggleSpeaker is no-op');
      return;
    }
    await _agoraService.toggleSpeaker();
  }
  
  @override
  Future<void> switchCamera() async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - switchCamera is no-op');
      return;
    }
    await _agoraService.switchCamera();
  }
  
  @override
  Future<void> renewToken(String token) async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - renewToken is no-op');
      return;
    }
    await _agoraService.renewToken(token);
  }
  
  @override
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    if (kIsWeb) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Video calling not supported on Web',
        icon: Icons.web,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
    
    final engine = _agoraService.engine;
    if (engine == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.black,
        child: Center(
          child: Text(
            'Engine not initialized',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return CrossPlatformVideoView(
      engine: engine,
      uid: 0, // Local video always uses uid 0
      isLocal: true,
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
    if (kIsWeb) {
      return CrossPlatformVideoViewFactory.createPlaceholderView(
        label: 'Video calling not supported on Web',
        icon: Icons.web,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
    
    final engine = _agoraService.engine;
    if (engine == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.black,
        child: Center(
          child: Text(
            'Engine not initialized',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return CrossPlatformVideoView(
      engine: engine,
      uid: uid,
      isLocal: false,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
  
  @override
  void dispose() {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('🌐 AgoraUnifiedServiceAdapter: Web platform - dispose is no-op');
      return;
    }
    _agoraService.dispose();
  }
}