import 'dart:async';
import 'dart:developer';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'storage_repository.dart';
import 'firebase_storage_repository.dart';
import 'media_picker_service.dart';
import 'notification_service.dart';
import 'encryption_key_manager.dart';
import 'package:raabta/features/auth/domain/user_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_profile_repository.dart';
import 'package:raabta/features/chat/domain/chat_repository.dart';
import 'package:raabta/features/chat/domain/firebase_chat_repository.dart';
import 'package:raabta/features/chat/domain/group_chat_repository.dart';
import 'package:raabta/features/chat/domain/firebase_group_chat_repository.dart';
import 'package:raabta/features/call/domain/repositories/call_repository.dart';
import 'package:raabta/features/call/data/firebase_call_repository.dart';
import 'call_service.dart';
import 'package:flutter/foundation.dart';

/// Service locator for dependency injection
/// This allows for easy replacement of services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Singleton instance
  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  /// Backend service instance
  BackendService? _backendService;

  /// Auth provider instance
  AuthProvider? _authProvider;

  /// User repository instance
  UserRepository? _userRepository;

  /// User profile repository instance
  UserProfileRepository? _userProfileRepository;

  /// Chat repository instance
  ChatRepository? _chatRepository;

  /// Group chat repository instance
  GroupChatRepository? _groupChatRepository;

  /// Storage repository instance
  FirebaseStorageRepository? _storageRepository;

  /// Media picker service instance
  MediaPickerService? _mediaPickerService;

  /// Notification service instance
  NotificationService? _notificationService;

  /// Encryption key manager instance
  EncryptionKeyManager? _encryptionKeyManager;

  /// Call repository instance
  CallRepository? _callRepository;

  /// Call service instance
  CallService? _callService;

  /// Track initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  /// Initialize services
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        log('🔧 ServiceLocator already initialized');
      }
      return;
    }

    if (_isInitializing) {
      if (kDebugMode) {
        log('🔧 ServiceLocator initialization in progress, waiting...');
      }
      // Wait for initialization to complete with timeout
      int waitCount = 0;
      while (_isInitializing && !_isInitialized && waitCount < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_isInitialized) return;
      throw Exception('ServiceLocator initialization timeout');
    }

    _isInitializing = true;

    try {
      if (kDebugMode) {
        log('🔧 Initializing ServiceLocator...');
        log('🌐 Platform: ${kIsWeb ? 'Web' : 'Native'}');
      }

      // Initialize backend service with timeout
      _backendService = FirebaseService();
      
      // Add timeout for Firebase initialization with better web handling
      try {
        await _backendService!.initialize().timeout(
          kIsWeb ? const Duration(seconds: 5) : const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              log('⏰ Firebase initialization timeout in ServiceLocator');
            }
            throw TimeoutException('Firebase initialization timeout', kIsWeb ? const Duration(seconds: 5) : const Duration(seconds: 10));
          },
        );
      } catch (e) {
        if (kDebugMode) {
          log('❌ Firebase service initialization failed: $e');
        }
        // For web, continue with degraded mode instead of throwing
        if (kIsWeb) {
          if (kDebugMode) {
            log('🌐 Web: Continuing with degraded Firebase services');
          }
        } else {
          rethrow;
        }
      }

      // Initialize auth provider
      _authProvider = FirebaseAuthService();

      // Initialize user repository
      _userRepository = FirebaseUserRepository();

      // Initialize user profile repository
      _userProfileRepository = FirebaseUserProfileRepository();

      // Initialize storage repository
      _storageRepository = FirebaseStorageRepository();

      // Initialize encryption key manager
      _encryptionKeyManager = EncryptionKeyManager();

      // Initialize chat repository with storage dependency
      _chatRepository = FirebaseChatRepository(
        storageRepository: _storageRepository!,
        encryptionKeyManager: _encryptionKeyManager!,
      );

      // Initialize group chat repository
      _groupChatRepository = FirebaseGroupChatRepository(
        storageRepository: _storageRepository!,
        encryptionKeyManager: _encryptionKeyManager!,
      );

      // Initialize media picker service
      _mediaPickerService = MediaPickerService();

      // Initialize notification service
      _notificationService = NotificationService();
      await _notificationService!.initialize();

      // Initialize call repository
      _callRepository = FirebaseCallRepository();

      // Initialize call service
      _callService = CallService();
      await _callService!.initialize();

      _isInitialized = true;
      
      if (kDebugMode) {
        log('✅ ServiceLocator initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ ServiceLocator initialization failed: $e');
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get backend service
  BackendService get backendService {
    if (_backendService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _backendService!;
  }

  /// Get auth provider
  AuthProvider get authProvider {
    if (_authProvider == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _authProvider!;
  }

  /// Get user repository
  UserRepository get userRepository {
    if (_userRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _userRepository!;
  }

  /// Get user profile repository
  UserProfileRepository get userProfileRepository {
    if (_userProfileRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _userProfileRepository!;
  }

  /// Get chat repository
  ChatRepository get chatRepository {
    if (_chatRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _chatRepository!;
  }

  /// Get group chat repository
  GroupChatRepository get groupChatRepository {
    if (_groupChatRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _groupChatRepository!;
  }

  /// Get storage repository
  StorageRepository get storageRepository {
    if (_storageRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _storageRepository!;
  }

  /// Get media picker service
  MediaPickerService get mediaPickerService {
    if (_mediaPickerService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _mediaPickerService!;
  }

  /// Get notification service
  NotificationService get notificationService {
    if (_notificationService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _notificationService!;
  }

  /// Get encryption key manager
  EncryptionKeyManager get encryptionKeyManager {
    if (_encryptionKeyManager == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _encryptionKeyManager!;
  }

  /// Get call repository
  CallRepository get callRepository {
    if (_callRepository == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _callRepository!;
  }

  /// Get call service
  CallService get callService {
    if (_callService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _callService!;
  }

  /// Safe getters that return null if not initialized
  AuthProvider? get authProviderOrNull => _authProvider;
  UserRepository? get userRepositoryOrNull => _userRepository;
  UserProfileRepository? get userProfileRepositoryOrNull => _userProfileRepository;
  BackendService? get backendServiceOrNull => _backendService;
  NotificationService? get notificationServiceOrNull => _notificationService;
  EncryptionKeyManager? get encryptionKeyManagerOrNull => _encryptionKeyManager;
  CallRepository? get callRepositoryOrNull => _callRepository;
  CallService? get callServiceOrNull => _callService;
}
