import 'models/user_profile_model.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  /// Save a user profile to the database
  Future<void> saveUserProfile(UserProfileModel userProfile);

  /// Get a user profile by their UID
  Future<UserProfileModel?> getUserProfile(String uid);

  /// Check if a user profile exists in the database
  Future<bool> userProfileExists(String uid);

  /// Update a user profile's last sign-in time
  Future<void> updateLastSignIn(String uid);

  /// Update specific profile fields
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates);

  /// Create initial profile from Firebase user data
  Future<UserProfileModel> createInitialProfile({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
    required DateTime? createdAt,
    DateTime? dateOfBirth,
  });

  /// Mark profile as complete
  Future<void> markProfileComplete(String uid);

  /// Get all users for group creation
  Future<List<UserProfileModel>> getAllUsers();
}