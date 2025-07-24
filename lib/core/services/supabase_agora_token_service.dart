import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Production-ready Supabase Agora Token Service
/// Replaces Firebase Functions with secure Supabase Edge Functions
class SupabaseAgoraTokenService {
  static final SupabaseAgoraTokenService _instance = SupabaseAgoraTokenService._internal();
  factory SupabaseAgoraTokenService() => _instance;
  SupabaseAgoraTokenService._internal();

  late final SupabaseService _supabaseService;
  bool _isInitialized = false;
  
  // Token cache for optimization
  final Map<String, AgoraTokenResponse> _tokenCache = {};

  /// Initialize with dependency injection
  void initializeWithDependencies(SupabaseService supabaseService) {
    if (_isInitialized) return;
    _supabaseService = supabaseService;
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('✅ SupabaseAgoraTokenService: Initialized with dependencies');
    }
  }
  
  /// Generate Agora token using Supabase Edge Function with HMAC-SHA256 security
  Future<AgoraTokenResponse> generateToken({
    required String channelName,
    int? uid,
    String role = 'publisher',
    int? expirationTime,
  }) async {
    if (!_isInitialized) {
      throw StateError('SupabaseAgoraTokenService not initialized. Call initializeWithDependencies() first.');
    }

    try {
      if (kDebugMode) {
        debugPrint('🎯 SupabaseAgoraTokenService: Generating token for channel: $channelName');
      }

      // Generate UID if not provided
      final finalUid = uid ?? _generateRandomUid();
      final finalExpirationTime = expirationTime ?? 3600;

      // Create cache key
      final cacheKey = '${channelName}_${finalUid}_${role}_$finalExpirationTime';
      
      // Check cache first
      if (_tokenCache.containsKey(cacheKey)) {
        final cachedToken = _tokenCache[cacheKey]!;
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Return cached token if it's still valid (with 5 minute buffer)
        if (cachedToken.expirationTime > currentTime + 300) {
          if (kDebugMode) {
            debugPrint('✅ SupabaseAgoraTokenService: Using cached token');
          }
          return cachedToken;
        } else {
          // Remove expired token from cache
          _tokenCache.remove(cacheKey);
        }
      }

      // Call Supabase Edge Function
      final response = await _supabaseService.invokeFunction(
        'generate-agora-token',
        body: {
          'channelName': channelName,
          'uid': finalUid,
          'role': role,
          'expirationTime': finalExpirationTime,
        },
      );

      if (response.status == 200 && response.data != null) {
        final tokenResponse = AgoraTokenResponse.fromMap(response.data);
        
        // Cache the token
        _tokenCache[cacheKey] = tokenResponse;
        
        if (kDebugMode) {
          debugPrint('✅ SupabaseAgoraTokenService: Secure token generated via Supabase Edge Function');
          debugPrint('📋 Token expires at: ${DateTime.fromMillisecondsSinceEpoch(tokenResponse.expirationTime * 1000)}');
          debugPrint('🔐 Token length: ${tokenResponse.rtcToken.length} characters');
        }

        return tokenResponse;
      } else {
        throw Exception('Supabase Edge Function returned error: ${response.status} - ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SupabaseAgoraTokenService: Failed to generate token: $e');
      }
      throw AgoraTokenException('Failed to generate Agora token via Supabase: $e');
    }
  }

  /// Generate a random UID for the user (positive 32-bit integer)
  int _generateRandomUid() {
    // Generate a random UID between 1 and 2^31-1 (max signed int32)
    return DateTime.now().millisecondsSinceEpoch % 2147483647 + 1;
  }

  /// Clear token cache (useful for logout/cleanup)
  void clearCache() {
    _tokenCache.clear();
    if (kDebugMode) {
      debugPrint('🧹 SupabaseAgoraTokenService: Token cache cleared');
    }
  }

  /// Check if a token is about to expire (within 5 minutes)
  bool isTokenExpiring(AgoraTokenResponse token) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return token.expirationTime <= currentTime + 300;
  }

  /// Refresh token if it's about to expire
  Future<AgoraTokenResponse> refreshTokenIfNeeded(
    AgoraTokenResponse currentToken, {
    String? role,
  }) async {
    if (isTokenExpiring(currentToken)) {
      if (kDebugMode) {
        debugPrint('🔄 SupabaseAgoraTokenService: Token expiring, refreshing...');
      }
      
      return await generateToken(
        channelName: currentToken.channelName,
        uid: currentToken.uid,
        role: role ?? 'publisher',
      );
    }
    
    return currentToken;
  }
}

/// Agora Token Response Model
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
    return 'AgoraTokenResponse(uid: $uid, channelName: $channelName, appId: $appId, hasToken: ${rtcToken.isNotEmpty}, expiresAt: ${DateTime.fromMillisecondsSinceEpoch(expirationTime * 1000)})';
  }
}

/// Agora Token Exception
class AgoraTokenException implements Exception {
  final String message;
  const AgoraTokenException(this.message);

  @override
  String toString() => 'AgoraTokenException: $message';
}