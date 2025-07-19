import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for gender options
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static Gender? fromString(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Gender.preferNotToSay,
    );
  }
}

/// Enum for relationship status options
enum RelationshipStatus {
  single,
  inRelationship,
  married,
  divorced,
  widowed,
  complicated,
  preferNotToSay;

  String get displayName {
    switch (this) {
      case RelationshipStatus.single:
        return 'Single';
      case RelationshipStatus.inRelationship:
        return 'In a relationship';
      case RelationshipStatus.married:
        return 'Married';
      case RelationshipStatus.divorced:
        return 'Divorced';
      case RelationshipStatus.widowed:
        return 'Widowed';
      case RelationshipStatus.complicated:
        return 'It\'s complicated';
      case RelationshipStatus.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static RelationshipStatus? fromString(String? value) {
    if (value == null) return null;
    return RelationshipStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelationshipStatus.preferNotToSay,
    );
  }
}

/// Model representing a user's complete profile information
class UserProfileModel {
  // Basic user info (from authentication)
  final String uid;
  final String email;
  final DateTime createdAt;
  final DateTime lastSignIn;

  // Required fields for profile setup
  final String name;
  final Gender gender;
  final String activeHours; // e.g., "9 AM - 6 PM"

  // Optional fields
  final String? photoUrl;
  final String? bio;
  final String? religion;
  final RelationshipStatus? relationshipStatus;
  final DateTime? dateOfBirth;

  // Profile completion status
  final bool isProfileComplete;

  UserProfileModel({
    required this.uid,
    required this.email,
    required this.createdAt,
    required this.lastSignIn,
    required this.name,
    required this.gender,
    required this.activeHours,
    this.photoUrl,
    this.bio,
    this.religion,
    this.relationshipStatus,
    this.dateOfBirth,
    required this.isProfileComplete,
  });

  /// Create a UserProfileModel from Firebase user data (for initial setup)
  factory UserProfileModel.fromFirebaseUser({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
    required DateTime? createdAt,
    DateTime? dateOfBirth,
  }) {
    final now = DateTime.now();
    return UserProfileModel(
      uid: uid,
      email: email ?? '',
      name: displayName ?? 'User',
      gender: Gender.preferNotToSay, // Default value
      activeHours: '9 AM - 6 PM', // Default value
      photoUrl: photoURL,
      createdAt: createdAt ?? now,
      lastSignIn: now,
      isProfileComplete: false, // Needs to be completed
      dateOfBirth: dateOfBirth,
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': Timestamp.fromDate(lastSignIn),
      'name': name,
      'gender': gender.name,
      'activeHours': activeHours,
      'photoUrl': photoUrl,
      'bio': bio,
      'religion': religion,
      'relationshipStatus': relationshipStatus?.name,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Create a UserProfileModel from a Firestore document
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastSignIn: (map['lastSignIn'] as Timestamp).toDate(),
      name: map['name'] as String,
      gender: Gender.fromString(map['gender'] as String?) ?? Gender.preferNotToSay,
      activeHours: map['activeHours'] as String? ?? '9 AM - 6 PM',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      religion: map['religion'] as String?,
      relationshipStatus: RelationshipStatus.fromString(map['relationshipStatus'] as String?),
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
    );
  }

  /// Create a copy of this UserProfileModel with updated fields
  UserProfileModel copyWith({
    String? uid,
    String? email,
    DateTime? createdAt,
    DateTime? lastSignIn,
    String? name,
    Gender? gender,
    String? activeHours,
    String? photoUrl,
    String? bio,
    String? religion,
    RelationshipStatus? relationshipStatus,
    DateTime? dateOfBirth,
    bool? isProfileComplete,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      activeHours: activeHours ?? this.activeHours,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      religion: religion ?? this.religion,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  /// Check if all required fields are filled
  bool get hasRequiredFields {
    return name.isNotEmpty && activeHours.isNotEmpty;
  }
}