import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_options.dart';

/// Abstract class for backend services
/// This allows for easy replacement with other services like Supabase or Appwrite
abstract class BackendService {
  /// Initialize the backend service
  Future<void> initialize();

  /// Check if the service is initialized
  bool get isInitialized;
}

/// Firebase implementation of BackendService
class FirebaseService implements BackendService {
  static final FirebaseService _instance = FirebaseService._internal();

  /// Singleton instance
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _initialized = true;

      if (kDebugMode) {
        print('Firebase initialized successfully');

        // Print platform-specific information
        if (kIsWeb) {
          print('Running on Web platform');
        } else {
          print('Running on ${defaultTargetPlatform.toString()} platform');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }
}
