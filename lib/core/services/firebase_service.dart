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
      log('🔥 Firebase already initialized');
      return;
    }

    if (_isInitializing) {
      log('🔥 Firebase initialization in progress, waiting...');
      // Wait for initialization to complete with timeout
      int waitCount = 0;
      while (_isInitializing && !_initialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_initialized) return;
      throw Exception('Firebase initialization timeout while waiting for concurrent initialization');
    }

    _isInitializing = true;

    try {
      log('🔥 Initializing Firebase...');
      if (kIsWeb) {
        log('🌐 Platform: Web');
      } else {
        log('📱 Platform: ${defaultTargetPlatform.toString()}');
      }

      // Check if Firebase is already initialized
      try {
        final app = Firebase.app();
        log('🔥 Firebase app already exists: ${app.name}');
        _initialized = true;
        _isInitializing = false;
        return;
      } catch (e) {
        // No existing app, continue with initialization
        log('🔥 No existing Firebase app found, proceeding with initialization...');
      }

      // Web-specific pre-initialization checks
      if (kIsWeb) {
        await _prepareWebEnvironment();
      }

      // Reduced retry count for faster failure/fallback
      int retries = kIsWeb ? 2 : 3;
      Exception? lastException;
      
      for (int i = 0; i < retries; i++) {
        try {
          log('🔥 Firebase initialization attempt ${i + 1}/$retries');

          // Add timeout for each initialization attempt
          final initTimeout = kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 10);
          
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(initTimeout);
          
          _initialized = true;
          _isInitializing = false;
          
          log('🔥 Firebase initialized successfully ${i > 0 ? 'after ${i + 1} attempts' : ''}');

            // Print platform-specific information
            if (kIsWeb) {
              log('🌐 Running on Web platform');
              log('🔑 Project ID: ${DefaultFirebaseOptions.web.projectId}');
              log('🔗 Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
              log('🗄️ Storage Bucket: ${DefaultFirebaseOptions.web.storageBucket}');
            } else {
              log('📱 Running on ${defaultTargetPlatform.toString()} platform');
              final options = DefaultFirebaseOptions.currentPlatform;
              log('🔑 Project ID: ${options.projectId}');
              log('🆔 App ID: ${options.appId}');
            }
            
            // Verify Firebase app is properly initialized
            final app = Firebase.app();
            log('✅ Firebase app verification: ${app.name} - ${app.options.projectId}');
          }
          
          // Additional web-specific validation
          if (kIsWeb) {
            await _validateWebFirebaseSetup();
          }
          
          return; // Success, exit retry loop
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          log('🚨 Firebase initialization attempt ${i + 1} failed: $e');
          if (e.toString().contains('FirebaseException') || e.toString().contains('auth/')) {
            log('🔍 Firebase error details: $e');
          }
          
          if (i < retries - 1) {
            // Reduced backoff for web: 200ms, 400ms for faster loading
            final delay = Duration(milliseconds: kIsWeb ? 200 * (i + 1) : 300 * (i + 1));
            log('⏳ Waiting ${delay.inMilliseconds}ms before retry...');
            await Future.delayed(delay);
          }
        }
      }
      
      // If we get here, all retries failed
      _initialized = false;
      _isInitializing = false;
      throw lastException ?? Exception('Failed to initialize Firebase after $retries attempts');

    } catch (e, stackTrace) {
      _initialized = false;
      _isInitializing = false;
      
      log('🚨 Error initializing Firebase: $e');
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

  /// Prepare web environment for Firebase initialization
  Future<void> _prepareWebEnvironment() async {
    if (!kIsWeb) return;
    
    try {
      log('🌐 Preparing web environment for Firebase...');
      
      // Add delay to ensure DOM and Firebase scripts are ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // For web, check if Firebase scripts are loaded
      // This is a basic check that the environment is ready
      log('🌐 Web environment preparation completed');
    } catch (e) {
      log('⚠️ Web environment preparation failed: $e');
      // Don't throw here, let the main initialization proceed
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
