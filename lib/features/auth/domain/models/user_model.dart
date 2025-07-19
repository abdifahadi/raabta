import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the application
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastSignIn;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastSignIn,
  });

  /// Create a UserModel from a Firebase user
  factory UserModel.fromFirebaseUser({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
    required DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      name: displayName ?? 'User',
      email: email ?? '',
      photoUrl: photoURL,
      createdAt: createdAt ?? now,
      lastSignIn: now,
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': Timestamp.fromDate(lastSignIn),
    };
  }

  /// Create a UserModel from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastSignIn: (map['lastSignIn'] as Timestamp).toDate(),
    );
  }

  /// Create a copy of this UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
}
