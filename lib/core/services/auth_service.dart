import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'firebase_service.dart';

/// Abstract class for authentication services
/// This allows for easy replacement with other auth providers
abstract class AuthProvider {
  /// Get the current user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  );

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle();

  /// Sign out
  Future<void> signOut();
}

/// Firebase implementation of AuthProvider
class FirebaseAuthService implements AuthProvider {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  /// Singleton instance
  factory FirebaseAuthService() => _instance;

  FirebaseAuthService._internal();

  FirebaseAuth get _auth {
    // Check if Firebase is initialized before accessing
    final firebaseService = FirebaseService();
    if (!firebaseService.isInitialized) {
      if (kDebugMode) {
        print('⚠️ Firebase not initialized, but AuthService is being accessed');
      }
      // Instead of throwing, we'll let Firebase.instance handle the error
      // This allows for better error handling in the UI
    }
    return FirebaseAuth.instance;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error getting current user: $e');
      }
      return null;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error getting auth state changes: $e');
      }
      // Return a stream that emits null to indicate no user
      return Stream.value(null);
    }
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // For web platform
      if (kIsWeb) {
        // Create a new provider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // Add scopes
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Set language
        googleProvider.setCustomParameters({
          'locale': 'en', // English language
        });

        // Sign in with popup for better UX on web
        return await _auth.signInWithPopup(googleProvider);
      }
      // For mobile platforms
      else {
        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google sign in aborted');
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
