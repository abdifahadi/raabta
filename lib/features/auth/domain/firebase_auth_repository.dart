import 'package:firebase_auth/firebase_auth.dart';
import 'package:raabta/core/services/auth_service.dart' as auth_service;
import 'package:raabta/core/services/service_locator.dart';
import 'auth_repository.dart';
import 'user_repository.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final auth_service.AuthProvider _authProvider;
  final UserRepository _userRepository;

  /// Constructor with dependency injection
  FirebaseAuthRepository({
    auth_service.AuthProvider? authProvider,
    UserRepository? userRepository,
  }) : _authProvider = authProvider ?? ServiceLocator().authProvider,
       _userRepository = userRepository ?? ServiceLocator().userRepository;

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
