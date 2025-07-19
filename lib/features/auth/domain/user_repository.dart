import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Save a user to the database
  Future<void> saveUser(UserModel user);

  /// Get a user by their UID
  Future<UserModel?> getUserById(String uid);

  /// Check if a user exists in the database
  Future<bool> userExists(String uid);

  /// Update a user's last sign-in time
  Future<void> updateLastSignIn(String uid);

  /// Save or update user after sign-in
  Future<UserModel> saveUserFromSignIn(User firebaseUser);
}
