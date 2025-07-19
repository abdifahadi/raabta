import 'auth_service.dart';
import 'firebase_service.dart';
import 'package:raabta/features/auth/domain/user_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_profile_repository.dart';

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
  }

  /// Get backend service
  BackendService get backendService => _backendService;

  /// Get auth provider
  AuthProvider get authProvider => _authProvider;

  /// Get user repository
  UserRepository get userRepository => _userRepository;

  /// Get user profile repository
  UserProfileRepository get userProfileRepository => _userProfileRepository;
}
