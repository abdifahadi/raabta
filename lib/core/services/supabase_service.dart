import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service for managing backend operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase configuration
  static const String _supabaseUrl = 'https://qrtutnrcynfceshsngph.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFydHV0bnJjeW5mY2VzaHNuZ3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNDA4MDMsImV4cCI6MjA2ODgxNjgwM30.TsnPqlCaTLKAVL32ygDv_sR71AEtLw1pJGHezmBeDBA';

  bool _isInitialized = false;

  /// Initialize Supabase
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('✅ SupabaseService: Already initialized');
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ SupabaseService: Initialized successfully');
        debugPrint('🔗 Supabase URL: $_supabaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SupabaseService: Failed to initialize: $e');
      }
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Get Supabase client instance
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('SupabaseService not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  /// Check if Supabase is initialized
  bool get isInitialized => _isInitialized;

  /// Call a Supabase Edge Function
  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 SupabaseService: Invoking function $functionName');
        if (body != null) {
          debugPrint('📦 Request body: $body');
        }
      }

      final response = await client.functions.invoke(
        functionName,
        body: body,
        headers: headers,
      );

      if (kDebugMode) {
        debugPrint('✅ SupabaseService: Function $functionName response received');
        debugPrint('📊 Status: ${response.status}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SupabaseService: Function $functionName failed: $e');
      }
      rethrow;
    }
  }

  /// Get Supabase URL
  String get supabaseUrl => _supabaseUrl;

  /// Get anon key
  String get anonKey => _supabaseAnonKey;
}