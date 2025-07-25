import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../agora/agora_service.dart';
import '../agora/cross_platform_video_view.dart';
import 'agora_service_interface.dart';
import 'production_agora_service.dart';
import '../../features/call/domain/models/call_model.dart';

/// Factory for creating Agora service instances
/// Now uses the new AgoraService with agora_rtc_engine 6.5.2
class AgoraServiceFactory {
  static AgoraServiceInterface? _instance;
  
  /// Get the unified AgoraService implementation for all platforms
  /// Uses agora_rtc_engine 6.5.2 with cross-platform support for Web, Android, iOS, Windows, macOS, Linux
  static AgoraServiceInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    // Use the production AgoraService for all platforms with agora_rtc_engine 6.5.2
    _instance = ProductionAgoraService();
    
    return _instance!;
  }
  
  /// Get the raw AgoraService instance (new implementation)
  static AgoraService getNewService() {
    return AgoraService();
  }
  
  /// Reset the instance (useful for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  /// Check if current platform supports Agora natively
  /// Now all platforms are supported through agora_rtc_engine 6.5.2
  static bool get isNativeSupported => true;
  
  /// Check if current platform is web
  static bool get isWebPlatform => kIsWeb;
}

/// Adapter to make the new AgoraService compatible with the existing interface
class AgoraUnifiedServiceAdapter implements AgoraServiceInterface {
  final AgoraService _agoraService = AgoraService();
  
  @override
  bool get isInCall => _agoraService.isInCall;
  
  @override
  bool get isVideoEnabled => _agoraService.isVideoEnabled;
  
  @override
  bool get isMuted => _agoraService.isMuted;
  
  @override
  bool get isSpeakerEnabled => _agoraService.isSpeakerEnabled;
  
  @override
  String? get currentChannelName => _agoraService.currentChannelName;
  
  @override
  int? get currentUid => _agoraService.currentUid;
  
  @override
  Set<int> get remoteUsers => _agoraService.remoteUsers;
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => _agoraService.callEventStream;
  
  @override
  Stream<CallModel?> get currentCallStream => _agoraService.currentCallStream;
  
  @override
  Future<void> initialize() async {
    await _agoraService.initializeEngine('4bfa94cebfb04852951bfdf9858dbc4b'); // Using the appId from AgoraConfig
  }
  
  @override
  Future<bool> checkPermissions(CallType callType) async {
    return await _agoraService.checkPermissions(callType);
  }
  
  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    // Get token from the service
    final token = ''; // Will be handled internally by the service
    await _agoraService.joinChannel(token, channelName, uid ?? 0);
  }
  
  @override
  Future<void> leaveCall() async {
    await _agoraService.leaveChannel();
  }
  
  @override
  Future<void> toggleMute() async {
    await _agoraService.toggleMute();
  }
  
  @override
  Future<void> toggleVideo() async {
    await _agoraService.toggleVideo();
  }
  
  @override
  Future<void> toggleSpeaker() async {
    await _agoraService.toggleSpeaker();
  }
  
  @override
  Future<void> switchCamera() async {
    await _agoraService.switchCamera();
  }
  
  @override
  Future<void> renewToken(String token) async {
    await _agoraService.renewToken(token);
  }
  
  @override
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
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
    _agoraService.dispose();
  }
}