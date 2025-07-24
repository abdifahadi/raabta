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
import 'agora_token_service.dart';
import 'ringtone_service.dart';
import 'supabase_service.dart';
import 'supabase_agora_token_service.dart';
import 'production_call_service.dart';
import 'call_manager.dart';

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

  /// Agora token service instance (legacy)
  AgoraTokenService? _agoraTokenService;

  /// Supabase Agora token service instance (production)
  SupabaseAgoraTokenService? _supabaseAgoraTokenService;

  /// Production call service instance (primary)
  ProductionCallService? _productionCallService;

  /// Ringtone service instance
  RingtoneService? _ringtoneService;

  /// Supabase service instance
  SupabaseService? _supabaseService;

  /// Call manager instance
  CallManager? _callManager;

  /// Track initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get initializationError => _initializationError;

  /// Initialize services with proper dependency order
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
      // Wait for initialization to complete
      return _initializationCompleter.future;
    }

    _isInitializing = true;
    _initializationError = null;

    try {
      if (kDebugMode) {
        log('🔧 Initializing ServiceLocator...');
        log('🌐 Platform: ${kIsWeb ? 'Web' : 'Native'}');
      }

      // Phase 1: Initialize core services (no dependencies)
      await _initializeCoreServices();
      
      // Phase 2: Initialize storage and authentication services
      await _initializeStorageServices();
      
      // Phase 3: Initialize chat and communication services
      await _initializeCommunicationServices();
      
      // Phase 4: Initialize call-related services
      await _initializeCallServices();

      _isInitialized = true;
      _initializationCompleter.complete();
      
      if (kDebugMode) {
        log('✅ ServiceLocator initialized successfully');
        log('✅ All services registered and ready');
      }
    } catch (e, stackTrace) {
      _initializationError = e.toString();
      if (kDebugMode) {
        log('❌ ServiceLocator initialization failed: $e');
        log('🔍 Stack trace: $stackTrace');
      }
      _initializationCompleter.completeError(e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Phase 1: Initialize core services with no dependencies
  Future<void> _initializeCoreServices() async {
    if (kDebugMode) {
      log('📋 Phase 1: Initializing core services...');
    }

    // Initialize backend service with timeout
    _backendService = FirebaseService();
    
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

    // Initialize media picker service
    _mediaPickerService = MediaPickerService();

    // Initialize Supabase service
    _supabaseService = SupabaseService();
    try {
      await _supabaseService!.initialize();
      if (kDebugMode) {
        log('✅ Supabase service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        log('⚠️ Supabase service initialization failed: $e');
      }
      // Continue without Supabase for now, but log the error
    }

    if (kDebugMode) {
      log('✅ Phase 1 completed: Core services initialized');
    }
  }

  /// Phase 2: Initialize storage and authentication services
  Future<void> _initializeStorageServices() async {
    if (kDebugMode) {
      log('📋 Phase 2: Initializing storage services...');
    }

    // Initialize storage repository
    _storageRepository = FirebaseStorageRepository();

    // Initialize encryption key manager
    _encryptionKeyManager = EncryptionKeyManager();

    // Initialize notification service
    _notificationService = NotificationService();
    await _notificationService!.initialize();

    if (kDebugMode) {
      log('✅ Phase 2 completed: Storage services initialized');
    }
  }

  /// Phase 3: Initialize communication services that depend on storage
  Future<void> _initializeCommunicationServices() async {
    if (kDebugMode) {
      log('📋 Phase 3: Initializing communication services...');
    }

    // Initialize chat repository with storage dependency
    _chatRepository = FirebaseChatRepository(
      storageRepository: _storageRepository!,
      encryptionKeyManager: _encryptionKeyManager!,
    );

    // Initialize group chat repository
    _groupChatRepository = FirebaseGroupChatRepository(
      firestore: null, // Use default FirebaseFirestore instance
      storageRepository: _storageRepository!,
      encryptionKeyManager: _encryptionKeyManager!,
    );

    // Initialize call repository
    _callRepository = FirebaseCallRepository();

    if (kDebugMode) {
      log('✅ Phase 3 completed: Communication services initialized');
    }
  }

  /// Phase 4: Initialize call services with proper dependency injection
  Future<void> _initializeCallServices() async {
    if (kDebugMode) {
      log('📋 Phase 4: Initializing call services...');
    }

    try {
      // Initialize ringtone service first (no dependencies)
      _ringtoneService = RingtoneService();
      if (kDebugMode) {
        log('✅ RingtoneService initialized');
      }

      // Initialize Agora token services with error handling
      try {
        _agoraTokenService = AgoraTokenService();
        if (kDebugMode) {
          log('✅ AgoraTokenService initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          log('⚠️ AgoraTokenService initialization failed: $e');
        }
        // Continue without legacy token service
      }

      // Initialize Supabase Agora token service (critical for production)
      try {
        _supabaseAgoraTokenService = SupabaseAgoraTokenService();
        if (_supabaseService != null) {
          _supabaseAgoraTokenService!.initializeWithDependencies(_supabaseService!);
          if (kDebugMode) {
            log('✅ SupabaseAgoraTokenService initialized with dependencies');
          }
        } else {
          if (kDebugMode) {
            log('⚠️ SupabaseService not available for token service');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          log('❌ SupabaseAgoraTokenService initialization failed: $e');
        }
        throw Exception('Critical service SupabaseAgoraTokenService failed to initialize: $e');
      }

      // Initialize call service and wait for it to complete
      try {
        _callService = CallService();
        await _callService!.initialize();
        if (kDebugMode) {
          log('✅ CallService initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          log('❌ CallService initialization failed: $e');
        }
        throw Exception('Critical service CallService failed to initialize: $e');
      }

      // Initialize production call service with safe dependency injection
      try {
        _productionCallService = ProductionCallService();
        if (_ringtoneService != null) {
          await _productionCallService!.initializeWithDependencies(_ringtoneService!);
        } else {
          await _productionCallService!.initialize();
        }
        if (kDebugMode) {
          log('✅ ProductionCallService initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          log('❌ ProductionCallService initialization failed: $e');
        }
        throw Exception('Critical service ProductionCallService failed to initialize: $e');
      }

      // Initialize call manager last (depends on call service)
      try {
        _callManager = CallManager();
        if (kDebugMode) {
          log('✅ CallManager initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          log('❌ CallManager initialization failed: $e');
        }
        throw Exception('Critical service CallManager failed to initialize: $e');
      }

      if (kDebugMode) {
        log('✅ Phase 4 completed: All call services initialized successfully');
        log('🎯 Available services: RingtoneService, CallService, ProductionCallService, CallManager');
        if (_supabaseAgoraTokenService != null) {
          log('🔐 Token service: SupabaseAgoraTokenService (Production)');
        }
        if (_agoraTokenService != null) {
          log('🔐 Token service: AgoraTokenService (Legacy/Backup)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ Phase 4 failed: Call services initialization error: $e');
      }
      rethrow;
    }
  }

  /// Get backend service
  BackendService get backendService {
    if (!_isInitialized) {
      throw StateError('ServiceLocator not initialized. Call initialize() first. Error: ${_initializationError ?? "Unknown error"}');
    }
    if (_backendService == null) {
      throw StateError('Backend service not available. Initialization may have failed. Error: ${_initializationError ?? "Service not created"}');
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

  /// Get Agora token service (legacy)
  AgoraTokenService get agoraTokenService {
    if (_agoraTokenService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _agoraTokenService!;
  }

  /// Get Supabase Agora token service (production)
  SupabaseAgoraTokenService get supabaseAgoraTokenService {
    if (_supabaseAgoraTokenService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _supabaseAgoraTokenService!;
  }

  /// Get production call service (primary)
  ProductionCallService get productionCallService {
    if (_productionCallService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _productionCallService!;
  }

  /// Get ringtone service
  RingtoneService get ringtoneService {
    if (_ringtoneService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _ringtoneService!;
  }

  /// Get Supabase service
  SupabaseService get supabaseService {
    if (_supabaseService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _supabaseService!;
  }

  /// Get call manager
  CallManager get callManager {
    if (!_isInitialized) {
      throw StateError('ServiceLocator not initialized. Call initialize() first. Error: ${_initializationError ?? "Unknown error"}');
    }
    if (_callManager == null) {
      throw StateError('CallManager not available. Call service initialization may have failed. Error: ${_initializationError ?? "Service not created"}');
    }
    return _callManager!;
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
  RingtoneService? get ringtoneServiceOrNull => _ringtoneService;
  AgoraTokenService? get agoraTokenServiceOrNull => _agoraTokenService;
  SupabaseAgoraTokenService? get supabaseAgoraTokenServiceOrNull => _supabaseAgoraTokenService;
  ProductionCallService? get productionCallServiceOrNull => _productionCallService;
  SupabaseService? get supabaseServiceOrNull => _supabaseService;
  CallManager? get callManagerOrNull => _callManager;

  /// Reset all services (for testing or clean restart)
  Future<void> reset() async {
    if (kDebugMode) {
      log('🔄 Resetting ServiceLocator...');
    }

    _isInitialized = false;
    _isInitializing = false;
    _initializationError = null;

    // Dispose services that need cleanup
    _callManager = null;
    _productionCallService = null;
    _callService = null;
    _ringtoneService = null;
    _notificationService = null;
    _supabaseService = null;
    _agoraTokenService = null;
    _supabaseAgoraTokenService = null;
    _callRepository = null;
    _groupChatRepository = null;
    _chatRepository = null;
    _encryptionKeyManager = null;
    _storageRepository = null;
    _mediaPickerService = null;
    _userProfileRepository = null;
    _userRepository = null;
    _authProvider = null;
    _backendService = null;

    if (kDebugMode) {
      log('✅ ServiceLocator reset completed');
    }
  }
}
