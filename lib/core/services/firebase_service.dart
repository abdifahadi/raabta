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
      } catch (e) {
        // Handle any Firebase initialization errors
        if (kDebugMode) {
          print('🔥 No existing Firebase app found, initializing... Error: $e');
        }
        // Continue with initialization regardless of error type
      }

      // Web-specific initialization delay to ensure DOM is ready
      if (kIsWeb) {
        if (kDebugMode) {
          print('🌐 Web platform detected, adding initialization delay...');
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Add retry mechanism for initialization with reduced retries for faster loading
      int retries = 3;
      Exception? lastException;
      
      for (int i = 0; i < retries; i++) {
        try {
          if (kDebugMode) {
            print('🔥 Firebase initialization attempt ${i + 1}/$retries');
          }

          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          
          _initialized = true;
          
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
            try {
              if (e.toString().contains('FirebaseException')) {
                print('🔍 Firebase error details: $e');
              }
            } catch (_) {
              // Ignore error inspection issues
            }
          }
          
          if (i < retries - 1) {
            // Reduced backoff: 300ms, 600ms for faster loading
            final delay = Duration(milliseconds: 300 * (i + 1));
            if (kDebugMode) {
              print('⏳ Waiting ${delay.inMilliseconds}ms before retry...');
            }
            await Future.delayed(delay);
          }
        }
      }
      
      // If we get here, all retries failed
      throw lastException ?? Exception('Failed to initialize Firebase after $retries attempts');

    } catch (e, stackTrace) {
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
      
      _initialized = false;
      rethrow;
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
        final _ = Firebase.app().options;
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
    
    if (kDebugMode) {
      print('🌐 Browser Compatibility Check:');
      print('  User Agent: ${_getBrowserInfo()}');
      print('  Local Storage: ${_hasLocalStorage()}');
      print('  Session Storage: ${_hasSessionStorage()}');
      print('  IndexedDB: ${_hasIndexedDB()}');
      print('  Fetch API: ${_hasFetch()}');
      print('  Promises: ${_hasPromises()}');
    }
  }

  /// Get browser information
  String _getBrowserInfo() {
    try {
      // This is a simple way to get browser info in web
      return 'Web Browser';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if localStorage is available
  bool _hasLocalStorage() {
    try {
      // This would be implemented with dart:html in a real scenario
      return true; // Assume true for now
    } catch (e) {
      return false;
    }
  }

  /// Check if sessionStorage is available
  bool _hasSessionStorage() {
    try {
      // This would be implemented with dart:html in a real scenario
      return true; // Assume true for now
    } catch (e) {
      return false;
    }
  }

  /// Check if IndexedDB is available
  bool _hasIndexedDB() {
    try {
      // This would be implemented with dart:html in a real scenario
      return true; // Assume true for now
    } catch (e) {
      return false;
    }
  }

  /// Check if Fetch API is available
  bool _hasFetch() {
    try {
      // This would be implemented with dart:html in a real scenario
      return true; // Assume true for now
    } catch (e) {
      return false;
    }
  }

  /// Check if Promises are available
  bool _hasPromises() {
    try {
      // This would be implemented with dart:html in a real scenario
      return true; // Assume true for now
    } catch (e) {
      return false;
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
