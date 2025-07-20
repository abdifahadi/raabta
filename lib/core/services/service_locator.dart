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

  /// Storage repository instance
  FirebaseStorageRepository? _storageRepository;

  /// Media picker service instance
  MediaPickerService? _mediaPickerService;

  /// Notification service instance
  NotificationService? _notificationService;

  /// Encryption key manager instance
  EncryptionKeyManager? _encryptionKeyManager;

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
        print('🔧 ServiceLocator already initialized');
      }
      return;
    }

    if (_isInitializing) {
      if (kDebugMode) {
        print('🔧 ServiceLocator initialization in progress, waiting...');
      }
      // Wait for initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      if (kDebugMode) {
        print('🔧 Initializing ServiceLocator...');
      }

      // Initialize backend service
      _backendService = FirebaseService();
      await _backendService!.initialize();

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

      // Initialize media picker service
      _mediaPickerService = MediaPickerService();

      // Initialize notification service
      _notificationService = NotificationService();
      await _notificationService!.initialize();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ ServiceLocator initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ServiceLocator initialization failed: $e');
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

  /// Safe getters that return null if not initialized
  AuthProvider? get authProviderOrNull => _authProvider;
  UserRepository? get userRepositoryOrNull => _userRepository;
  UserProfileRepository? get userProfileRepositoryOrNull => _userProfileRepository;
  BackendService? get backendServiceOrNull => _backendService;
  NotificationService? get notificationServiceOrNull => _notificationService;
  EncryptionKeyManager? get encryptionKeyManagerOrNull => _encryptionKeyManager;
}
