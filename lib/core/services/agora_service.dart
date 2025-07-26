import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class AgoraService {
  static RtcEngine? _engine;

  static Future<void> initAgora({
    required String appId,
    required String token,
    required String channelName,
    required int uid,
  }) async {
    // Note: Web platform calling is disabled in this version
    if (kIsWeb) {
      debugPrint('🌐 AgoraService: Web platform calling disabled - use mobile/desktop app');
      throw UnsupportedError('Video calling is not supported on Web platform. Please use the mobile or desktop app.');
    }
    
    try {
      debugPrint('🚀 AgoraService: Initializing with agora_rtc_engine 6.5.2...');
      
      // Create engine with modern API
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Configure engine
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      debugPrint('✅ AgoraService: Engine initialized successfully');
      
      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint("✅ AgoraService: Join success on ${connection.channelId}");
          },
          onUserJoined: (connection, remoteUid, elapsed) { 
            debugPrint("🎉 AgoraService: User $remoteUid joined");
          },
          onUserOffline: (connection, remoteUid, reason) { 
            debugPrint("🚫 AgoraService: User $remoteUid left");
          },
          onError: (err, msg) { 
            debugPrint("❌ AgoraService: Error: $err - $msg");
          },
          onConnectionStateChanged: (connection, state, reason) {
            debugPrint("🔗 AgoraService: Connection state: $state, reason: $reason");
          },
        ),
      );
      
      debugPrint('✅ AgoraService: Event handlers registered');
      
      // Join channel with enhanced options
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      );
      
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: options,
      );
      
      debugPrint('✅ AgoraService: Successfully joined channel $channelName');
    } catch (e) {
      debugPrint('❌ AgoraService: Initialization failed: $e');
      rethrow;
    }
  }

  static Future<void> disposeAgora() async {
    if (_engine != null) {
      debugPrint('🧹 AgoraService: Disposing engine...');
      
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
        
        debugPrint('✅ AgoraService: Engine disposed successfully');
      } catch (e) {
        debugPrint('❌ AgoraService: Error during disposal: $e');
      }
    }
  }

  /// Get the current engine instance
  static RtcEngine? get engine => _engine;

  /// Check if engine is initialized
  static bool get isInitialized => _engine != null;

  // Legacy aliases for backward compatibility
  static Future<void> initialize({
    required String appId,
    required String token,
    required String channelName,
    required int uid,
  }) async {
    return initAgora(
      appId: appId,
      token: token,
      channelName: channelName,
      uid: uid,
    );
  }

  static Future<void> leaveChannel() async {
    return disposeAgora();
  }
}