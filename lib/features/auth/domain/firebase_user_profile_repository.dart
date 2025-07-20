import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_profile_model.dart';
import 'user_profile_repository.dart';

/// Firebase implementation of UserProfileRepository
class FirebaseUserProfileRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'users';

  /// Constructor with dependency injection
  FirebaseUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(_collectionPath);

  @override
  Future<void> saveUserProfile(UserProfileModel userProfile) async {
    try {
      await _usersCollection.doc(userProfile.uid).set(userProfile.toMap());
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserProfileModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<bool> userProfileExists(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Failed to check if user profile exists: $e');
    }
  }

  @override
  Future<void> updateLastSignIn(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastSignIn': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update last sign-in: $e');
    }
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      // Add timestamp for the update
      final updateData = Map<String, dynamic>.from(updates);
      updateData['lastSignIn'] = Timestamp.fromDate(DateTime.now());
      
      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> createInitialProfile({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
    required DateTime? createdAt,
    DateTime? dateOfBirth,
  }) async {
    try {
      final userProfile = UserProfileModel.fromFirebaseUser(
        uid: uid,
        displayName: displayName,
        email: email,
        photoURL: photoURL,
        createdAt: createdAt,
        dateOfBirth: dateOfBirth,
      );
      
      await saveUserProfile(userProfile);
      return userProfile;
    } catch (e) {
      throw Exception('Failed to create initial profile: $e');
    }
  }

  @override
  Future<void> markProfileComplete(String uid) async {
    try {
      await updateUserProfile(uid, {
        'isProfileComplete': true,
      });
    } catch (e) {
      throw Exception('Failed to mark profile as complete: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserProfileModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }
}