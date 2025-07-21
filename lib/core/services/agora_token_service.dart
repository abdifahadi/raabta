import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AgoraTokenService {
  static final AgoraTokenService _instance = AgoraTokenService._internal();
  factory AgoraTokenService() => _instance;
  AgoraTokenService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate Agora token using Firebase Cloud Function
  Future<AgoraTokenResponse> generateToken({
    required String channelName,
    int? uid,
    String role = 'publisher',
    int? expirationTime,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 Generating Agora token for channel: $channelName');
      }

      final callable = _functions.httpsCallable('generateAgoraToken');
      
      final result = await callable.call({
        'channelName': channelName,
        'uid': uid,
        'role': role,
        'expirationTime': expirationTime,
      });

      if (kDebugMode) {
        debugPrint('✅ Agora token generated successfully');
      }

      return AgoraTokenResponse.fromMap(result.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to generate Agora token: $e');
      }
      throw AgoraTokenException('Failed to generate token: $e');
    }
  }
}

class AgoraTokenResponse {
  final String rtcToken;
  final int uid;
  final String channelName;
  final String appId;
  final int expirationTime;

  const AgoraTokenResponse({
    required this.rtcToken,
    required this.uid,
    required this.channelName,
    required this.appId,
    required this.expirationTime,
  });

  factory AgoraTokenResponse.fromMap(Map<String, dynamic> map) {
    return AgoraTokenResponse(
      rtcToken: map['rtcToken'] as String,
      uid: map['uid'] as int,
      channelName: map['channelName'] as String,
      appId: map['appId'] as String,
      expirationTime: map['expirationTime'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rtcToken': rtcToken,
      'uid': uid,
      'channelName': channelName,
      'appId': appId,
      'expirationTime': expirationTime,
    };
  }

  @override
  String toString() {
    return 'AgoraTokenResponse(uid: $uid, channelName: $channelName, appId: $appId)';
  }
}

class AgoraTokenException implements Exception {
  final String message;
  const AgoraTokenException(this.message);

  @override
  String toString() => 'AgoraTokenException: $message';
}