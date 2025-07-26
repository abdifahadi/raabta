// Web stub for Agora RTC Engine
// This file provides empty implementations to prevent compilation errors on Web

import 'dart:async';
import 'package:flutter/material.dart';

// Stub implementations for Web platform
class RtcEngine {
  // Initialize method
  Future<void> initialize(RtcEngineContext context) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Event handler registration
  void registerEventHandler(RtcEngineEventHandler eventHandler) {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Video methods
  Future<void> enableVideo() async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> enableAudio() async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> enableLocalVideo(bool enabled) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Channel methods
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    ChannelMediaOptions? options,
  }) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> leaveChannel() async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Audio/Video control
  Future<void> muteLocalAudioStream(bool mute) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> muteLocalVideoStream(bool mute) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> setEnableSpeakerphone(bool enabled) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> switchCamera() async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Configuration methods
  Future<void> setAudioProfile({
    required AudioProfileType profile,
    required AudioScenarioType scenario,
  }) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> setVideoEncoderConfiguration(VideoEncoderConfiguration configuration) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  Future<void> setDefaultAudioRouteToSpeakerphone(bool defaultToSpeaker) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Token renewal
  Future<void> renewToken(String token) async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
  
  // Cleanup
  Future<void> release() async {
    throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
  }
}

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

// Video view related stubs for web
class AgoraVideoView extends StatelessWidget {
  final VideoViewController controller;
  final Function(int)? onAgoraVideoViewCreated;
  
  const AgoraVideoView({
    super.key,
    required this.controller,
    this.onAgoraVideoViewCreated,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Video not supported on Web',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

class VideoViewController {
  final RtcEngine rtcEngine;
  final VideoCanvas canvas;
  
  VideoViewController({
    required this.rtcEngine,
    required this.canvas,
  });
  
  VideoViewController.remote({
    required this.rtcEngine,
    required this.canvas,
    RtcConnection? connection,
  });
}

class VideoCanvas {
  final int uid;
  final RenderModeType? renderMode;
  final VideoMirrorModeType? mirrorMode;
  
  const VideoCanvas({
    required this.uid,
    this.renderMode,
    this.mirrorMode,
  });
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
enum RenderModeType { renderModeHidden }
enum VideoMirrorModeType { videoMirrorModeAuto, videoMirrorModeDisabled }

// Native platform video view stub for web
class PlatformVideoView extends StatelessWidget {
  final RtcEngine engine;
  final int uid;
  final bool isLocal;
  final String? channelId;

  const PlatformVideoView({
    super.key,
    required this.engine,
    required this.uid,
    required this.isLocal,
    this.channelId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Video not supported on Web',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

// Stub functions
RtcEngine createAgoraRtcEngine() {
  throw UnsupportedError('Agora RTC Engine is not supported on Web platform');
}