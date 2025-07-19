import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:raabta/features/auth/presentation/profile_setup_screen.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';
import 'package:raabta/core/services/service_locator.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthRepository _authRepository = FirebaseAuthRepository();
  final UserProfileRepository _userProfileRepository = ServiceLocator().userProfileRepository;
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      await _authRepository.signInWithGoogle();
      
      if (mounted) {
        // Get the current user
        final user = _authRepository.currentUser;
        if (user != null) {
          // Check if user profile exists and is complete
          final existingProfile = await _userProfileRepository.getUserProfile(user.uid);
          
          if (existingProfile != null && existingProfile.isProfileComplete) {
            // Profile is complete, go to home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // Profile doesn't exist or is incomplete, go to profile setup
            final initialProfile = existingProfile ?? 
                await _userProfileRepository.createInitialProfile(
                  uid: user.uid,
                  displayName: user.displayName,
                  email: user.email,
                  photoURL: user.photoURL,
                  createdAt: user.metadata.creationTime,
                );
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ProfileSetupScreen(
                  initialProfile: initialProfile,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Center(
                child: Text(
                  'Raabta',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connect with your contacts',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              GoogleSignInButton(
                onPressed: _signInWithGoogle,
                isLoading: _isSigningIn,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
