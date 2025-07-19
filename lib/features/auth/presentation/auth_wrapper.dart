import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/presentation/sign_in_screen.dart';
import 'package:raabta/features/auth/presentation/profile_setup_screen.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';
import 'package:raabta/core/services/service_locator.dart';

/// A wrapper widget that handles authentication state changes
class AuthWrapper extends StatelessWidget {
  final AuthRepository _authRepository = FirebaseAuthRepository();
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        // If the snapshot has user data, then the user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Check if user profile exists and is complete
          return FutureBuilder(
            future: _userProfileRepository.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                // Show loading while checking profile
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final profile = profileSnapshot.data;
              if (profile != null && profile.isProfileComplete) {
                // Profile is complete, show home
                return const HomeScreen();
              } else {
                // Profile doesn't exist or is incomplete, show profile setup
                if (profile != null) {
                  return ProfileSetupScreen(initialProfile: profile);
                } else {
                  // Create initial profile and show setup
                  return FutureBuilder(
                    future: _userProfileRepository.createInitialProfile(
                      uid: user.uid,
                      displayName: user.displayName,
                      email: user.email,
                      photoURL: user.photoURL,
                      createdAt: user.metadata.creationTime,
                    ),
                    builder: (context, createSnapshot) {
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      if (createSnapshot.hasData) {
                        return ProfileSetupScreen(initialProfile: createSnapshot.data!);
                      } else {
                        // Error creating profile, sign out
                        _authRepository.signOut();
                        return const SignInScreen();
                      }
                    },
                  );
                }
              }
            },
          );
        }

        // Otherwise, the user is not signed in
        return const SignInScreen();
      },
    );
  }
}
