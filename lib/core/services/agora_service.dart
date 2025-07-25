import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import '../helpers/permission_web_helper.dart';

class AgoraService {
  static RtcEngine? _engine;

  static Future<void> initAgora({
    required String appId,
    required String token,
    required String channelName,
    required int uid,
  }) async {
    // Request web permissions first if on web platform
    if (kIsWeb) {
      await requestWebPermissions();
    }
    
    // Create engine with context (modern API)
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));
    await _engine!.enableVideo();
    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) =>
            print("✅ Join success on ${connection.channelId}"),
        onUserJoined: (connection, remoteUid, elapsed) => 
            print("🎉 User $remoteUid joined"),
        onUserOffline: (connection, remoteUid, reason) => 
            print("🚫 User $remoteUid left"),
        onError: (err, msg) => 
            print("❌ Agora Error: $err - $msg"),
      ),
    );
    
    // Join channel
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  static Future<void> disposeAgora() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }

  // Legacy alias for backward compatibility
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

  // Legacy alias for backward compatibility
  static Future<void> leaveChannel() async {
    return disposeAgora();
  }
}