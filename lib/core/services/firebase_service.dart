import 'dart:developer';
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
  bool _isInitializing = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      log('🔥 Firebase service already initialized');
      return;
    }

    if (_isInitializing) {
      log('🔥 Firebase service initialization in progress, waiting...');
      // Wait for initialization to complete with timeout
      int waitCount = 0;
      while (_isInitializing && !_initialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_initialized) return;
      throw Exception('Firebase service initialization timeout while waiting for concurrent initialization');
    }

    _isInitializing = true;

    try {
      log('🔥 Checking Firebase initialization status...');
      if (kIsWeb) {
        log('🌐 Platform: Web');
      } else {
        log('📱 Platform: ${defaultTargetPlatform.toString()}');
      }

      // ✅ FIREBASE FIX: Check if Firebase is already initialized (should be from main.dart)
      if (Firebase.apps.isNotEmpty) {
        final app = Firebase.app();
        log('🔥 Firebase app already exists: ${app.name} - Project: ${app.options.projectId}');
        
        // Additional verification that Firebase is truly ready
        if (kIsWeb) {
          log('🌐 Verifying web Firebase readiness...');
          // For web, we can do additional checks here if needed
        }
        
        _initialized = true;
        _isInitializing = false;
        
        if (kDebugMode) {
          log('✅ Firebase service initialization completed (using existing app)');
        }
        return;
      }

      // ✅ FIREBASE FIX: If no apps exist, this is an error state since main.dart should initialize Firebase
      log('❌ Firebase not initialized by main.dart - this should not happen in normal flow');
      throw Exception('Firebase should be initialized before FirebaseService.initialize() is called');

    } catch (e, stackTrace) {
      _initialized = false;
      _isInitializing = false;
      
      log('🚨 Error initializing Firebase service: $e');
      log('🔍 Stack trace: $stackTrace');
      
      // Additional debugging for web
      if (kIsWeb) {
        log('🌐 Web Firebase Config Check:');
        log('  API Key: ${DefaultFirebaseOptions.web.apiKey.isNotEmpty ? '[SET - ${DefaultFirebaseOptions.web.apiKey.length} chars]' : '[MISSING]'}');
        log('  Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
        log('  Project ID: ${DefaultFirebaseOptions.web.projectId}');
        log('  Storage Bucket: ${DefaultFirebaseOptions.web.storageBucket}');
        log('  Messaging Sender ID: ${DefaultFirebaseOptions.web.messagingSenderId}');
        log('  App ID: ${DefaultFirebaseOptions.web.appId}');
        log('  Measurement ID: ${DefaultFirebaseOptions.web.measurementId ?? '[NOT SET]'}');
        
        // Check browser compatibility
        _checkWebCompatibility();
      }
      
      rethrow;
    }
  }

  /// Validate Firebase setup specifically for web
  Future<void> _validateWebFirebaseSetup() async {
    if (!kIsWeb) return;
    
    try {
      log('🌐 Validating web Firebase setup...');
      
      // Check if Firebase Auth is available
      try {
        final app = Firebase.app();
        final _ = app.options;
        log('✅ Firebase options accessible');
      } catch (e) {
        log('⚠️ Firebase options validation failed: $e');
        throw Exception('Firebase configuration validation failed: $e');
      }
      
      log('✅ Web Firebase setup validation completed');
    } catch (e) {
      log('🚨 Web Firebase validation failed: $e');
      throw Exception('Web Firebase validation failed: $e');
    }
  }

  /// Check web browser compatibility
  void _checkWebCompatibility() {
    if (!kIsWeb) return;
    
    try {
      log('🌐 Checking web browser compatibility...');
      log('  User Agent: [Browser detection not available in Flutter]');
      log('  Note: Ensure you\'re using a modern browser with JavaScript enabled');
      log('  Supported: Chrome 63+, Firefox 57+, Safari 10.1+, Edge 79+');
    } catch (e) {
      log('⚠️ Browser compatibility check failed: $e');
    }
  }

  /// Reset initialization state (for testing)
  void reset() {
    _initialized = false;
  }

  /// Get detailed Firebase configuration info (for debugging)
  Map<String, dynamic> getConfigInfo() {
    if (!_initialized) {
      return {'status': 'not_initialized'};
    }

    try {
      final app = Firebase.app();
      final options = app.options;
      
      return {
        'status': 'initialized',
        'app_name': app.name,
        'project_id': options.projectId,
        'app_id': options.appId,
        'api_key_length': options.apiKey.length,
        'auth_domain': options.authDomain,
        'storage_bucket': options.storageBucket,
        'messaging_sender_id': options.messagingSenderId,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}
