import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service for calling Firebase Cloud Functions
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance = FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;
  FirebaseFunctionsService._internal();

  FirebaseFunctions? _functions;

  /// Initialize Firebase Functions
  Future<void> initialize() async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      
      _functions = FirebaseFunctions.instance;
      
      // Use emulator for local development
      if (kDebugMode) {
        try {
          _functions!.useFunctionsEmulator('localhost', 5001);
          debugPrint('✅ Firebase Functions: Using local emulator on localhost:5001');
        } catch (e) {
          debugPrint('⚠️ Firebase Functions: Local emulator not available, using production');
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ Firebase Functions service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Firebase Functions: $e');
      }
      rethrow;
    }
  }

  /// Call a Firebase Cloud Function
  Future<Map<String, dynamic>?> callFunction(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      // Initialize if not already done
      if (_functions == null) {
        await initialize();
      }

      if (kDebugMode) {
        debugPrint('🚀 Calling Firebase Function: $functionName');
        if (data != null) {
          debugPrint('📦 Function data: $data');
        }
      }

      final callable = _functions!.httpsCallable(functionName);
      final result = await callable.call(data);

      if (kDebugMode) {
        debugPrint('✅ Firebase Function $functionName completed successfully');
      }

      return result.data as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Function $functionName failed: $e');
      }
      
      // Handle specific Firebase Functions errors
      if (e is FirebaseFunctionsException) {
        throw Exception('Firebase Function error (${e.code}): ${e.message}');
      }
      
      throw Exception('Failed to call Firebase Function $functionName: $e');
    }
  }

  /// Check if Firebase Functions is available
  bool get isAvailable => _functions != null;

  /// Get the Firebase Functions instance
  FirebaseFunctions? get functions => _functions;
}