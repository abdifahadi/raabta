import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static Future<void> initialize({
    required String appId,
    required String token,
    required String channelName,
    required int uid,
  }) async {
    await AgoraRtcEngine.create(appId);
    await AgoraRtcEngine.enableVideo();
    await AgoraRtcEngine.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await AgoraRtcEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    AgoraRtcEngine.registerEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        print("✅ Joined channel $channel as $uid");
      },
      userJoined: (uid, elapsed) {
        print("🎯 User $uid joined");
      },
      userOffline: (uid, reason) {
        print("⚠️ User $uid left ($reason)");
      },
    ));

    await AgoraRtcEngine.joinChannel(
      token,
      channelName,
      null,
      uid,
    );
  }

  static Future<void> leaveChannel() async {
    await AgoraRtcEngine.leaveChannel();
    await AgoraRtcEngine.destroy();
  }
}