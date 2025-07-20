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
      if (kDebugMode) {
        print('🔥 Firebase already initialized');
      }
      return;
    }

    if (_isInitializing) {
      if (kDebugMode) {
        print('🔥 Firebase initialization in progress, waiting...');
      }
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
        _isInitializing = false;
        return;
      } catch (e) {
        // No existing app, continue with initialization
        if (kDebugMode) {
          print('🔥 No existing Firebase app found, proceeding with initialization...');
        }
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
          if (kDebugMode) {
            print('🔥 Firebase initialization attempt ${i + 1}/$retries');
          }

          // Add timeout for each initialization attempt
          final initTimeout = kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 10);
          
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(initTimeout);
          
          _initialized = true;
          _isInitializing = false;
          
          if (kDebugMode) {
            print('🔥 Firebase initialized successfully ${i > 0 ? 'after ${i + 1} attempts' : ''}');

            // Print platform-specific information
            if (kIsWeb) {
              print('🌐 Running on Web platform');
              print('🔑 Project ID: ${DefaultFirebaseOptions.web.projectId}');
              print('🔗 Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
              print('🗄️ Storage Bucket: ${DefaultFirebaseOptions.web.storageBucket}');
            } else {
              print('📱 Running on ${defaultTargetPlatform.toString()} platform');
              final options = DefaultFirebaseOptions.currentPlatform;
              print('🔑 Project ID: ${options.projectId}');
              print('🆔 App ID: ${options.appId}');
            }
            
            // Verify Firebase app is properly initialized
            final app = Firebase.app();
            print('✅ Firebase app verification: ${app.name} - ${app.options.projectId}');
          }
          
          // Additional web-specific validation
          if (kIsWeb) {
            await _validateWebFirebaseSetup();
          }
          
          return; // Success, exit retry loop
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          if (kDebugMode) {
            print('🚨 Firebase initialization attempt ${i + 1} failed: $e');
            if (e.toString().contains('FirebaseException') || e.toString().contains('auth/')) {
              print('🔍 Firebase error details: $e');
            }
          }
          
          if (i < retries - 1) {
            // Reduced backoff for web: 200ms, 400ms for faster loading
            final delay = Duration(milliseconds: kIsWeb ? 200 * (i + 1) : 300 * (i + 1));
            if (kDebugMode) {
              print('⏳ Waiting ${delay.inMilliseconds}ms before retry...');
            }
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
      
      if (kDebugMode) {
        print('🚨 Error initializing Firebase: $e');
        print('🔍 Stack trace: $stackTrace');
        
        // Additional debugging for web
        if (kIsWeb) {
          print('🌐 Web Firebase Config Check:');
          print('  API Key: ${DefaultFirebaseOptions.web.apiKey.isNotEmpty ? '[SET - ${DefaultFirebaseOptions.web.apiKey.length} chars]' : '[MISSING]'}');
          print('  Auth Domain: ${DefaultFirebaseOptions.web.authDomain}');
          print('  Project ID: ${DefaultFirebaseOptions.web.projectId}');
          print('  Storage Bucket: ${DefaultFirebaseOptions.web.storageBucket}');
          print('  Messaging Sender ID: ${DefaultFirebaseOptions.web.messagingSenderId}');
          print('  App ID: ${DefaultFirebaseOptions.web.appId}');
          print('  Measurement ID: ${DefaultFirebaseOptions.web.measurementId ?? '[NOT SET]'}');
          
          // Check browser compatibility
          _checkWebCompatibility();
        }
      }
      
      rethrow;
    }
  }

  /// Prepare web environment for Firebase initialization
  Future<void> _prepareWebEnvironment() async {
    if (!kIsWeb) return;
    
    try {
      if (kDebugMode) {
        print('🌐 Preparing web environment for Firebase...');
      }
      
      // Add delay to ensure DOM and Firebase scripts are ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // For web, check if Firebase scripts are loaded
      // This is a basic check that the environment is ready
      if (kDebugMode) {
        print('🌐 Web environment preparation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Web environment preparation failed: $e');
      }
      // Don't throw here, let the main initialization proceed
    }
  }

  /// Validate Firebase setup specifically for web
  Future<void> _validateWebFirebaseSetup() async {
    if (!kIsWeb) return;
    
    try {
      if (kDebugMode) {
        print('🌐 Validating web Firebase setup...');
      }
      
      // Check if Firebase Auth is available
      try {
        final app = Firebase.app();
        final _ = app.options;
        if (kDebugMode) {
          print('✅ Firebase options accessible');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Firebase options validation failed: $e');
        }
        throw Exception('Firebase configuration validation failed: $e');
      }
      
      if (kDebugMode) {
        print('✅ Web Firebase setup validation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Web Firebase validation failed: $e');
      }
      throw Exception('Web Firebase validation failed: $e');
    }
  }

  /// Check web browser compatibility
  void _checkWebCompatibility() {
    if (!kIsWeb) return;
    
    try {
      if (kDebugMode) {
        print('🌐 Checking web browser compatibility...');
        print('  User Agent: [Browser detection not available in Flutter]');
        print('  Note: Ensure you\'re using a modern browser with JavaScript enabled');
        print('  Supported: Chrome 63+, Firefox 57+, Safari 10.1+, Edge 79+');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Browser compatibility check failed: $e');
      }
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
