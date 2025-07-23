import 'package:flutter/foundation.dart';
// DEPRECATED: Firebase Cloud Functions removed
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_core/firebase_core.dart';

/// DEPRECATED: Firebase Functions Service
/// This service has been replaced with Supabase Edge Functions
/// Use SupabaseAgoraTokenService instead for token generation
@deprecated
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance = FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;
  FirebaseFunctionsService._internal();

  /// DEPRECATED: Initialize Firebase Functions
  @deprecated
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
  @deprecated
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
  @deprecated
  bool get isAvailable => false;

  /// DEPRECATED: Get the Firebase Functions instance
  @deprecated
  dynamic get functions => null;
}