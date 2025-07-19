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
    if (_initialized) {
      if (kDebugMode) {
        print('🔥 Firebase already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔥 Initializing Firebase...');
        if (kIsWeb) {
          print('🌐 Platform: Web');
        } else {
          print('📱 Platform: ${defaultTargetPlatform.toString()}');
        }
      }

      // Check if Firebase is already initialized
      try {
        final app = Firebase.app();
        if (kDebugMode) {
          print('🔥 Firebase app already exists: ${app.name}');
        }
        _initialized = true;
        return;
      } on FirebaseException catch (e) {
        if (e.code == 'no-app') {
          // Firebase not initialized yet, continue with initialization
          if (kDebugMode) {
            print('🔥 No existing Firebase app found, initializing...');
          }
        } else {
          // Different Firebase error, rethrow
          rethrow;
        }
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _initialized = true;

      if (kDebugMode) {
        print('🔥 Firebase initialized successfully');

        // Print platform-specific information
        if (kIsWeb) {
          print('🌐 Running on Web platform');
          print('🔑 Project ID: ${DefaultFirebaseOptions.web.projectId}');
          print('🔗 Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
        } else {
          print('📱 Running on ${defaultTargetPlatform.toString()} platform');
          final options = DefaultFirebaseOptions.currentPlatform;
          print('🔑 Project ID: ${options.projectId}');
          print('🆔 App ID: ${options.appId}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🚨 Error initializing Firebase: $e');
        print('🔍 Stack trace: $stackTrace');
        
        // Additional debugging for web
        if (kIsWeb) {
          print('🌐 Web Firebase Config:');
          print('  API Key: ${DefaultFirebaseOptions.web.apiKey.isNotEmpty ? '[SET]' : '[MISSING]'}');
          print('  Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
          print('  Project ID: ${DefaultFirebaseOptions.web.projectId}');
          print('  Storage Bucket: ${DefaultFirebaseOptions.web.storageBucket}');
          print('  Messaging Sender ID: ${DefaultFirebaseOptions.web.messagingSenderId}');
          print('  App ID: ${DefaultFirebaseOptions.web.appId}');
          print('  Measurement ID: ${DefaultFirebaseOptions.web.measurementId}');
        }
      }
      
      _initialized = false;
      rethrow;
    }
  }

  /// Reset initialization state (for testing)
  void reset() {
    _initialized = false;
  }
}
