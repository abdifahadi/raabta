import 'package:firebase_auth/firebase_auth.dart';
import 'package:raabta/core/services/auth_service.dart' as auth_service;
import 'package:raabta/core/services/service_locator.dart';
import 'auth_repository.dart';
import 'user_repository.dart';
import 'firebase_user_repository.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final auth_service.AuthProvider _authProvider;
  final UserRepository _userRepository;

  /// Constructor with safe dependency injection
  FirebaseAuthRepository({
    auth_service.AuthProvider? authProvider,
    UserRepository? userRepository,
  }) : _authProvider = authProvider ?? _getAuthProvider(),
       _userRepository = userRepository ?? _getUserRepository();

  /// Safe getter for AuthProvider
  static auth_service.AuthProvider _getAuthProvider() {
    final serviceLocator = ServiceLocator();
    if (!serviceLocator.isInitialized) {
      // If not initialized, create a new instance directly
      return auth_service.FirebaseAuthService();
    }
    return serviceLocator.authProvider;
  }

  /// Safe getter for UserRepository
  static UserRepository _getUserRepository() {
    final serviceLocator = ServiceLocator();
    if (!serviceLocator.isInitialized) {
      // If not initialized, create a new instance directly
      return FirebaseUserRepository();
    }
    return serviceLocator.userRepository;
  }

  @override
  User? get currentUser => _authProvider.currentUser;

  @override
  Stream<User?> get authStateChanges => _authProvider.authStateChanges;

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      final userCredential = await _authProvider.signInWithGoogle();

      // Save user to Firestore
      if (userCredential.user != null) {
        await _userRepository.saveUserFromSignIn(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authProvider.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
