import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/presentation/sign_in_screen.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';

/// A wrapper widget that handles authentication state changes
class AuthWrapper extends StatelessWidget {
  final AuthRepository _authRepository = FirebaseAuthRepository();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        // If the snapshot has user data, then the user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Otherwise, the user is not signed in
        return const SignInScreen();
      },
    );
  }
}
