import 'auth_service.dart';
import 'firebase_service.dart';
import 'storage_repository.dart';
import 'firebase_storage_repository.dart';
import 'media_picker_service.dart';
import 'package:raabta/features/auth/domain/user_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_profile_repository.dart';
import 'package:raabta/features/chat/domain/chat_repository.dart';
import 'package:raabta/features/chat/domain/firebase_chat_repository.dart';

/// Service locator for dependency injection
/// This allows for easy replacement of services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Singleton instance
  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  /// Backend service instance
  late BackendService _backendService;

  /// Auth provider instance
  late AuthProvider _authProvider;

  /// User repository instance
  late UserRepository _userRepository;

  /// User profile repository instance
  late UserProfileRepository _userProfileRepository;

  /// Chat repository instance
  late ChatRepository _chatRepository;

  /// Storage repository instance
  late StorageRepository _storageRepository;

  /// Media picker service instance
  late MediaPickerService _mediaPickerService;

  /// Initialize services
  Future<void> initialize() async {
    // Initialize backend service
    _backendService = FirebaseService();
    await _backendService.initialize();

    // Initialize auth provider
    _authProvider = FirebaseAuthService();

    // Initialize user repository
    _userRepository = FirebaseUserRepository();

    // Initialize user profile repository
    _userProfileRepository = FirebaseUserProfileRepository();

    // Initialize chat repository
    _chatRepository = FirebaseChatRepository();

    // Initialize storage repository
    _storageRepository = FirebaseStorageRepository();

    // Initialize media picker service
    _mediaPickerService = MediaPickerService();
  }

  /// Get backend service
  BackendService get backendService => _backendService;

  /// Get auth provider
  AuthProvider get authProvider => _authProvider;

  /// Get user repository
  UserRepository get userRepository => _userRepository;

  /// Get user profile repository
  UserProfileRepository get userProfileRepository => _userProfileRepository;

  /// Get chat repository
  ChatRepository get chatRepository => _chatRepository;

  /// Get storage repository
  StorageRepository get storageRepository => _storageRepository;

  /// Get media picker service
  MediaPickerService get mediaPickerService => _mediaPickerService;
}
