import 'package:flutter/foundation.dart';
// DEPRECATED: Firebase Cloud Functions removed
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_core/firebase_core.dart';

/// DEPRECATED: Firebase Functions Service
/// This service has been replaced with Supabase Edge Functions
/// Use SupabaseAgoraTokenService instead for token generation
@Deprecated('Use SupabaseAgoraTokenService instead')
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance = FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;
  FirebaseFunctionsService._internal();

  /// DEPRECATED: Initialize Firebase Functions
  @Deprecated('Use SupabaseAgoraTokenService.initialize() instead')
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('⚠️ FirebaseFunctionsService is DEPRECATED');
      debugPrint('🔄 Please use SupabaseAgoraTokenService instead');
      debugPrint('📝 Firebase Cloud Functions have been replaced with Supabase Edge Functions');
    }
    throw UnsupportedError(
      'Firebase Cloud Functions have been removed. Use SupabaseAgoraTokenService instead.'
    );
  }

  /// DEPRECATED: Call a Firebase Cloud Function
  @Deprecated('Use SupabaseAgoraTokenService for token generation instead')
  Future<Map<String, dynamic>?> callFunction(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    if (kDebugMode) {
      debugPrint('❌ Attempted to call deprecated Firebase Function: $functionName');
      debugPrint('🔄 Use SupabaseAgoraTokenService.generateToken() instead');
    }
    
    throw UnsupportedError(
      'Firebase Cloud Functions have been removed. Use SupabaseAgoraTokenService instead.'
    );
  }

  /// DEPRECATED: Check if Firebase Functions is available
  @Deprecated('Firebase Functions are no longer used')
  bool get isAvailable => false;

  /// DEPRECATED: Get the Firebase Functions instance
  @Deprecated('Firebase Functions are no longer used')
  dynamic get functions => null;
}