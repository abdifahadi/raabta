import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/presentation/sign_in_screen.dart';
import 'package:raabta/features/auth/presentation/profile_setup_screen.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';
import 'package:raabta/core/services/service_locator.dart';

/// A wrapper widget that handles authentication state changes
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasTimeout = false;
  
  @override
  void initState() {
    super.initState();
    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _hasTimeout = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔐 Building AuthWrapper');
    }

    // Show timeout message if loading takes too long
    if (_hasTimeout) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_off,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading is taking longer than expected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasTimeout = false;
                  });
                  // Try again
                  Future.delayed(const Duration(seconds: 10), () {
                    if (mounted) {
                      setState(() {
                        _hasTimeout = true;
                      });
                    }
                  });
                },
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Force go to sign in screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final AuthRepository authRepository = FirebaseAuthRepository();
    final UserProfileRepository userProfileRepository = ServiceLocator().userProfileRepository;

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (kDebugMode) {
          print('🔐 Auth state change: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data}');
        }

        // Handle errors
        if (snapshot.hasError) {
          if (kDebugMode) {
            print('🚨 Auth stream error: ${snapshot.error}');
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to sign out and restart auth
                      authRepository.signOut();
                    },
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Force go to sign in screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                      );
                    },
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) {
            print('🔐 Waiting for auth state...');
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add app logo/icon here
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.chat,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading Raabta...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we set things up',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // If the snapshot has user data, then the user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          if (kDebugMode) {
            print('🔐 User is signed in: ${user.uid}');
          }
          
          // Check if user profile exists and is complete
          return FutureBuilder(
            future: userProfileRepository.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (kDebugMode) {
                print('🔐 Profile check: ${profileSnapshot.connectionState}, hasData: ${profileSnapshot.hasData}');
              }

              if (profileSnapshot.hasError) {
                if (kDebugMode) {
                  print('🚨 Profile fetch error: ${profileSnapshot.error}');
                }
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Loading Error',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${profileSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            authRepository.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) {
                  print('🔐 Loading user profile...');
                }
                // Show loading while checking profile
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add app logo/icon here
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.chat,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading profile...',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Setting up your account',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final profile = profileSnapshot.data;
              if (profile != null && profile.isProfileComplete) {
                if (kDebugMode) {
                  print('🔐 Profile is complete, showing home screen');
                }
                // Profile is complete, show home
                return const HomeScreen();
              } else {
                if (kDebugMode) {
                  print('🔐 Profile incomplete or missing, showing profile setup');
                }
                // Profile doesn't exist or is incomplete, show profile setup
                if (profile != null) {
                  return ProfileSetupScreen(initialProfile: profile);
                } else {
                  // Create initial profile and show setup
                  return FutureBuilder(
                    future: userProfileRepository.createInitialProfile(
                      uid: user.uid,
                      displayName: user.displayName,
                      email: user.email,
                      photoURL: user.photoURL,
                      createdAt: user.metadata.creationTime,
                    ),
                    builder: (context, createSnapshot) {
                      if (createSnapshot.hasError) {
                        if (kDebugMode) {
                          print('🚨 Profile creation error: ${createSnapshot.error}');
                        }
                        // Error creating profile, sign out
                        authRepository.signOut();
                        return const SignInScreen();
                      }
                      
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        if (kDebugMode) {
                          print('🔐 Creating initial profile...');
                        }
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Add app logo/icon here
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: const Icon(
                                    Icons.chat,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Setting up profile...',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Almost ready!',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (createSnapshot.hasData) {
                        if (kDebugMode) {
                          print('🔐 Initial profile created, showing setup screen');
                        }
                        return ProfileSetupScreen(initialProfile: createSnapshot.data!);
                      } else {
                        if (kDebugMode) {
                          print('🚨 Failed to create initial profile, signing out');
                        }
                        // Error creating profile, sign out
                        authRepository.signOut();
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
        if (kDebugMode) {
          print('🔐 User is not signed in, showing sign in screen');
        }
        return const SignInScreen();
      },
    );
  }
}
