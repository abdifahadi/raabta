import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'user_repository.dart';

/// Firebase implementation of UserRepository
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'users';

  /// Constructor with dependency injection
  FirebaseUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(_collectionPath);

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  @override
  Future<UserModel?> getUserById(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<bool> userExists(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Failed to check if user exists: $e');
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
  Future<UserModel> saveUserFromSignIn(User firebaseUser) async {
    try {
      final uid = firebaseUser.uid;
      final exists = await userExists(uid);

      if (exists) {
        // User exists, update last sign-in time
        await updateLastSignIn(uid);
        final user = await getUserById(uid);
        if (user != null) {
          return user.copyWith(lastSignIn: DateTime.now());
        }
        throw Exception('User exists but could not be retrieved');
      } else {
        // Create new user
        final newUser = UserModel.fromFirebaseUser(
          uid: uid,
          displayName: firebaseUser.displayName,
          email: firebaseUser.email,
          photoURL: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime,
        );
        await saveUser(newUser);
        return newUser;
      }
    } catch (e) {
      throw Exception('Failed to save user from sign-in: $e');
    }
  }
}
