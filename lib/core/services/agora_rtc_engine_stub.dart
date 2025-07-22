// Stub implementation for agora_rtc_engine on Web platform
// This prevents compilation errors when agora_rtc_engine is not available

import 'package:flutter/material.dart';

class RtcEngine {
  static RtcEngine? createAgoraRtcEngine() => null;
  
  Future<void> initialize(dynamic context) async {
    throw UnsupportedError('agora_rtc_engine not supported on Web');
  }
  
  Future<void> enableAudio() async {}
  Future<void> enableVideo() async {}
  Future<void> enableLocalVideo(bool enabled) async {}
  Future<void> startPreview() async {}
  Future<void> stopPreview() async {}
  Future<void> setDefaultAudioRouteToSpeakerphone(bool enabled) async {}
  Future<void> setVideoEncoderConfiguration(dynamic config) async {}
  Future<void> setClientRole({required dynamic role}) async {}
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required dynamic options,
  }) async {}
  Future<void> leaveChannel() async {}
  Future<void> muteLocalAudioStream(bool muted) async {}
  Future<void> setEnableSpeakerphone(bool enabled) async {}
  Future<void> switchCamera() async {}
  Future<void> renewToken(String token) async {}
  Future<void> release() async {}
  
  void registerEventHandler(dynamic handler) {}
}

class RtcEngineContext {
  final String appId;
  final dynamic channelProfile;
  final dynamic logConfig;
  
  RtcEngineContext({
    required this.appId,
    this.channelProfile,
    this.logConfig,
  });
}

class LogConfig {
  final dynamic level;
  final String filePath;
  
  LogConfig({
    required this.level,
    required this.filePath,
  });
}

class VideoEncoderConfiguration {
  final dynamic dimensions;
  final int frameRate;
  final int bitrate;
  final dynamic orientationMode;
  
  VideoEncoderConfiguration({
    required this.dimensions,
    required this.frameRate,
    required this.bitrate,
    required this.orientationMode,
  });
}

class VideoDimensions {
  final int width;
  final int height;
  
  VideoDimensions({
    required this.width,
    required this.height,
  });
}

class ChannelMediaOptions {
  final dynamic clientRoleType;
  final dynamic channelProfile;
  final bool autoSubscribeAudio;
  final bool autoSubscribeVideo;
  final bool publishCameraTrack;
  final bool publishMicrophoneTrack;
  
  ChannelMediaOptions({
    required this.clientRoleType,
    required this.channelProfile,
    required this.autoSubscribeAudio,
    required this.autoSubscribeVideo,
    required this.publishCameraTrack,
    required this.publishMicrophoneTrack,
  });
}

class AgoraVideoView extends StatelessWidget {
  final dynamic controller;
  
  const AgoraVideoView({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
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
  final dynamic canvas;
  
  VideoViewController({
    required this.rtcEngine,
    required this.canvas,
  });
  
  VideoViewController.remote({
    required RtcEngine rtcEngine,
    required dynamic canvas,
    required dynamic connection,
  }) : rtcEngine = rtcEngine, canvas = canvas;
}

class VideoCanvas {
  final int uid;
  
  const VideoCanvas({required this.uid});
}

class RtcConnection {
  final String? channelId;
  
  RtcConnection({this.channelId});
}

class RtcEngineEventHandler {
  final Function(RtcConnection, int)? onJoinChannelSuccess;
  final Function(RtcConnection, int, int)? onUserJoined;
  final Function(RtcConnection, int, dynamic)? onUserOffline;
  final Function(RtcConnection, dynamic)? onLeaveChannel;
  final Function(dynamic, String)? onError;
  final Function(RtcConnection, dynamic, dynamic)? onConnectionStateChanged;
  final Function(RtcConnection, String)? onTokenPrivilegeWillExpire;
  
  RtcEngineEventHandler({
    this.onJoinChannelSuccess,
    this.onUserJoined,
    this.onUserOffline,
    this.onLeaveChannel,
    this.onError,
    this.onConnectionStateChanged,
    this.onTokenPrivilegeWillExpire,
  });
}

// Enums and constants
enum ChannelProfileType { channelProfileCommunication }
enum LogLevel { logLevelInfo, logLevelWarn }
enum ClientRoleType { clientRoleBroadcaster }
enum OrientationMode { orientationModeAdaptive }
enum ErrorCodeType { unknown }
enum UserOfflineReasonType { unknown }
enum ConnectionStateType { unknown }
enum ConnectionChangedReasonType { unknown }

RtcEngine? createAgoraRtcEngine() => null;
