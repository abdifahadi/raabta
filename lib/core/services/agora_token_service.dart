import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../config/agora_config.dart';

class AgoraTokenService {
  static final AgoraTokenService _instance = AgoraTokenService._internal();
  factory AgoraTokenService() => _instance;
  AgoraTokenService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Development mode flag - in production, always use secure tokens
  static const bool _allowInsecureMode = kDebugMode;

  /// Generate Agora token using Firebase Cloud Function with fallback support
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

      // Generate UID if not provided
      final finalUid = uid ?? _generateRandomUid();

      try {
        // First, try to generate secure token via Firebase Cloud Function
        final callable = _functions.httpsCallable('generateAgoraToken');
        
        final result = await callable.call({
          'channelName': channelName,
          'uid': finalUid,
          'role': role,
          'expirationTime': expirationTime ?? AgoraConfig.tokenExpirationTime,
        });

        if (kDebugMode) {
          debugPrint('✅ Secure Agora token generated successfully via Cloud Function');
        }

        return AgoraTokenResponse.fromMap(result.data);
      } catch (cloudFunctionError) {
        if (kDebugMode) {
          debugPrint('⚠️ Cloud Function token generation failed: $cloudFunctionError');
        }
        
        // Fallback for development/testing - use null token (insecure mode)
        if (_allowInsecureMode) {
          if (kDebugMode) {
            debugPrint('🔓 Using insecure mode for development (no App Certificate required)');
          }
          
          return AgoraTokenResponse(
            rtcToken: '', // Empty token for testing without certificate
            uid: finalUid,
            channelName: channelName,
            appId: AgoraConfig.appId,
            expirationTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + AgoraConfig.tokenExpirationTime,
          );
        } else {
          // In production, rethrow the error
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to generate Agora token: $e');
      }
      throw AgoraTokenException('Failed to generate token: $e');
    }
  }
  
  /// Generate a random UID for the user
  int _generateRandomUid() {
    // Generate a random UID between 1 and 2^31-1 (max signed int32)
    return DateTime.now().millisecondsSinceEpoch % 2147483647 + 1;
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
    return 'AgoraTokenResponse(uid: $uid, channelName: $channelName, appId: $appId, hasToken: ${rtcToken.isNotEmpty})';
  }
}

class AgoraTokenException implements Exception {
  final String message;
  const AgoraTokenException(this.message);

  @override
  String toString() => 'AgoraTokenException: $message';
}