import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';

abstract class AgoraServiceInterface {
  // State getters
  bool get isInCall;
  bool get isVideoEnabled;
  bool get isMuted;
  bool get isSpeakerEnabled;
  String? get currentChannelName;
  int? get currentUid;
  Set<int> get remoteUsers;
  
  // Streams
  Stream<Map<String, dynamic>> get callEventStream;
  Stream<CallModel?> get currentCallStream;
  
  // Core methods
  Future<void> initialize();
  Future<bool> checkPermissions(CallType callType);
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  });
  Future<void> leaveCall();
  
  // Call controls
  Future<void> toggleMute();
  Future<void> toggleVideo();
  Future<void> toggleSpeaker();
  Future<void> switchCamera();
  
  // Token management
  Future<void> renewToken(String token);
  
  // Video views
  Widget createLocalVideoView({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  });
  Widget createRemoteVideoView(int uid, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  });
  
  // Cleanup
  void dispose();
}