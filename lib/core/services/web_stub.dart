// Web stub for Agora RTC Engine
// This file provides empty implementations to prevent compilation errors on Web

// Stub implementations for Web platform
class RtcEngine {}

class RtcEngineContext {
  final String appId;
  final ChannelProfileType? channelProfile;
  final int? areaCode;
  final LogConfig? logConfig;
  
  const RtcEngineContext({
    required this.appId,
    this.channelProfile,
    this.areaCode,
    this.logConfig,
  });
}

class RtcEngineEventHandler {
  final Function(RtcConnection, int)? onJoinChannelSuccess;
  final Function(RtcConnection, int, int)? onUserJoined;
  final Function(RtcConnection, int, UserOfflineReasonType)? onUserOffline;
  final Function(ErrorCodeType, String)? onError;
  final Function(RtcConnection, ConnectionStateType, ConnectionChangedReasonType)? onConnectionStateChanged;
  final Function(RtcConnection, int, RemoteVideoState, RemoteVideoStateReason, int)? onRemoteVideoStateChanged;
  final Function(RtcConnection, int, RemoteAudioState, RemoteAudioStateReason, int)? onRemoteAudioStateChanged;
  final Function(RtcConnection, int, QualityType, QualityType)? onNetworkQuality;
  final Function(RtcConnection, String)? onTokenPrivilegeWillExpire;

  const RtcEngineEventHandler({
    this.onJoinChannelSuccess,
    this.onUserJoined,
    this.onUserOffline,
    this.onError,
    this.onConnectionStateChanged,
    this.onRemoteVideoStateChanged,
    this.onRemoteAudioStateChanged,
    this.onNetworkQuality,
    this.onTokenPrivilegeWillExpire,
  });
}

class RtcConnection {
  final String channelId;
  final int localUid;
  
  const RtcConnection({required this.channelId, required this.localUid});
}

class ChannelMediaOptions {
  final ClientRoleType? clientRoleType;
  final ChannelProfileType? channelProfile;
  final bool? publishCameraTrack;
  final bool? publishMicrophoneTrack;
  final bool? publishScreenTrack;
  final bool? autoSubscribeVideo;
  final bool? autoSubscribeAudio;
  
  const ChannelMediaOptions({
    this.clientRoleType,
    this.channelProfile,
    this.publishCameraTrack,
    this.publishMicrophoneTrack,
    this.publishScreenTrack,
    this.autoSubscribeVideo,
    this.autoSubscribeAudio,
  });
}

class VideoEncoderConfiguration {
  final VideoDimensions? dimensions;
  final int? frameRate;
  final int? bitrate;
  final OrientationMode? orientationMode;
  final DegradationPreference? degradationPreference;
  
  const VideoEncoderConfiguration({
    this.dimensions,
    this.frameRate,
    this.bitrate,
    this.orientationMode,
    this.degradationPreference,
  });
}

class VideoDimensions {
  final int width;
  final int height;
  
  const VideoDimensions({required this.width, required this.height});
}

class LogConfig {
  final LogLevel? level;
  
  const LogConfig({this.level});
}

class AreaCode {
  static AreaCode areaCodeGlob = AreaCode._();
  AreaCode._();
  int value() => 0;
}

// Enums
enum ChannelProfileType { channelProfileCommunication }
enum ClientRoleType { clientRoleBroadcaster }
enum LogLevel { logLevelInfo, logLevelWarn }
enum AudioProfileType { audioProfileDefault }
enum AudioScenarioType { audioScenarioChatroom }
enum OrientationMode { orientationModeAdaptive }
enum DegradationPreference { maintainQuality }
enum UserOfflineReasonType { userOfflineQuit, userOfflineDropped }
enum ErrorCodeType { errTokenExpired, errNetDown, errFailed }
enum ConnectionStateType { connectionStateDisconnected, connectionStateReconnecting, connectionStateConnected }
enum ConnectionChangedReasonType { connectionChangedInterrupted }
enum RemoteVideoState { remoteVideoStateDecoding, remoteVideoStateFrozen, remoteVideoStateStopped }
enum RemoteVideoStateReason { remoteVideoStateReasonInternal }
enum RemoteAudioState { remoteAudioStateDecoding, remoteAudioStateFrozen, remoteAudioStateStopped }
enum RemoteAudioStateReason { remoteAudioStateReasonInternal }
enum QualityType { qualityPoor, qualityGood, qualityExcellent }

// Stub functions
RtcEngine createAgoraRtcEngine() {
  throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
}