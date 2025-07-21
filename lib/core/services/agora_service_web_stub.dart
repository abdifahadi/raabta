// Stub implementation for non-web platforms
// This file is used when dart:html is not available

import 'dart:async';

import 'package:flutter/material.dart';
import '../../features/call/domain/models/call_model.dart';
import 'agora_service_interface.dart';

class AgoraServiceWeb implements AgoraServiceInterface {
  static final AgoraServiceWeb _instance = AgoraServiceWeb._internal();
  factory AgoraServiceWeb() => _instance;
  AgoraServiceWeb._internal();

  // This should never be called on non-web platforms
  @override
  bool get isInCall => false;
  
  @override
  bool get isVideoEnabled => false;
  
  @override
  bool get isMuted => false;
  
  @override
  bool get isSpeakerEnabled => false;
  
  @override
  String? get currentChannelName => null;
  
  @override
  Set<int> get remoteUsers => <int>{};
  
  @override
  Stream<Map<String, dynamic>> get callEventStream => const Stream.empty();
  
  @override
  Stream<CallModel?> get currentCallStream => const Stream.empty();

  @override
  Future<void> initialize() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<bool> checkPermissions(CallType callType) async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> joinCall({
    required String channelName,
    required CallType callType,
    int? uid,
  }) async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> leaveCall() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> toggleMute() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> toggleVideo() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> toggleSpeaker() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Future<void> switchCamera() async {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Widget createLocalVideoView() {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  Widget createRemoteVideoView(int uid) {
    throw UnsupportedError('AgoraServiceWeb should not be used on non-web platforms');
  }

  @override
  void dispose() {
    // No-op for stub
  }
}