import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/agora_config.dart';
import 'firebase_functions_service.dart';

class AgoraTokenService {
  static final AgoraTokenService _instance = AgoraTokenService._internal();
  factory AgoraTokenService() => _instance;
  AgoraTokenService._internal();

  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  
  // Development mode flag - in production, always use secure tokens
  static const bool _allowInsecureMode = kDebugMode;

  /// Generate Agora token using Firebase Functions with in-app JWT fallback
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
        // Try Firebase Functions first
        final response = await _functionsService.callFunction(
          'generateAgoraToken',
          data: {
            'channelName': channelName,
            'uid': finalUid,
            'role': role,
            'expirationTime': expirationTime ?? 3600,
          },
        );

        if (response != null) {
          if (kDebugMode) {
            debugPrint('✅ Secure Agora token generated via Firebase Functions');
            debugPrint('📋 Token expires at: ${DateTime.fromMillisecondsSinceEpoch(response['expirationTime'] * 1000)}');
          }

          return AgoraTokenResponse.fromMap(response);
        } else {
          throw Exception('Firebase Functions returned null response');
        }
      } catch (functionsError) {
        if (kDebugMode) {
          debugPrint('⚠️ Firebase Functions token generation failed: $functionsError');
          debugPrint('🔄 Falling back to in-app token generation...');
        }
        
        // Fallback to in-app JWT generation using Agora certificate
        try {
          final token = await _generateTokenInApp(
            channelName: channelName,
            uid: finalUid,
            role: role,
            expirationTime: expirationTime ?? 3600,
          );
          
          if (kDebugMode) {
            debugPrint('✅ Agora token generated in-app using certificate');
          }
          
          return token;
        } catch (inAppError) {
          if (kDebugMode) {
            debugPrint('⚠️ In-app token generation failed: $inAppError');
          }
          
          // Final fallback for development/testing - use null token (insecure mode)
          if (_allowInsecureMode) {
            if (kDebugMode) {
              debugPrint('🔓 Using insecure mode for development (no App Certificate required)');
            }
            
            return AgoraTokenResponse(
              rtcToken: '', // Empty token for testing without certificate
              uid: finalUid,
              channelName: channelName,
              appId: AgoraConfig.appId,
              expirationTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expirationTime ?? 3600),
            );
          } else {
            // In production, rethrow the error
            rethrow;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to generate Agora token: $e');
      }
      throw AgoraTokenException('Failed to generate token: $e');
    }
  }
  
  /// Generate Agora token in-app using the app certificate
  Future<AgoraTokenResponse> _generateTokenInApp({
    required String channelName,
    required int uid,
    required String role,
    required int expirationTime,
  }) async {
    try {
      const appId = AgoraConfig.appId;
      const appCertificate = AgoraConfig.primaryCertificate;
      
      if (appCertificate.isEmpty) {
        throw Exception('App certificate not configured');
      }
      
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final privilegeExpiredTs = currentTimestamp + expirationTime;
      
      // Build token using simplified in-app implementation
      final token = await _buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        role == 'subscriber' ? 2 : 1,
        privilegeExpiredTs,
      );
      
      return AgoraTokenResponse(
        rtcToken: token,
        uid: uid,
        channelName: channelName,
        appId: appId,
        expirationTime: privilegeExpiredTs,
      );
    } catch (e) {
      throw Exception('In-app token generation failed: $e');
    }
  }
  
  /// Simplified in-app token generation (for fallback use)
  Future<String> _buildTokenWithUid(
    String appId,
    String appCertificate,
    String channelName,
    int uid,
    int role,
    int privilegeExpiredTs,
  ) async {
    try {
      // This is a simplified implementation
      // For production, you should use the full Agora token algorithm
      
      final message = _packMessage(
        appId,
        channelName,
        uid,
        privilegeExpiredTs,
        role,
      );
      
      final signature = _generateHmacSignature(appCertificate, message);
      
      final tokenData = signature + message;
      final token = '007' + base64Url.encode(tokenData.codeUnits);
      
      return token;
    } catch (e) {
      throw Exception('Token building failed: $e');
    }
  }
  
  /// Pack message for token generation
  String _packMessage(
    String appId,
    String channelName,
    int uid,
    int expiredTs,
    int role,
  ) {
    // Simplified message packing for in-app generation
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '$appId$channelName$uid$expiredTs$role$timestamp';
  }
  
  /// Generate HMAC signature
  String _generateHmacSignature(String key, String message) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString();
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