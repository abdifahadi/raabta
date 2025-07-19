import 'package:firebase_auth/firebase_auth.dart';

/// Abstract repository for authentication
/// This allows for easy replacement with other auth implementations
abstract class AuthRepository {
  /// Get the current user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle();

  /// Sign out
  Future<void> signOut();
}
