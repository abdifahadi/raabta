import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raabta/features/auth/domain/auth_repository.dart';
import 'package:raabta/features/auth/domain/firebase_auth_repository.dart';
import 'package:raabta/features/auth/domain/user_profile_repository.dart';
import 'package:raabta/features/auth/domain/firebase_user_profile_repository.dart';
import 'package:raabta/features/auth/presentation/sign_in_screen.dart';
import 'package:raabta/features/auth/presentation/profile_setup_screen.dart';
import 'package:raabta/features/auth/presentation/widgets/splash_screen.dart';
import 'package:raabta/features/auth/presentation/widgets/error_screen.dart';
import 'package:raabta/features/home/presentation/home_screen.dart';
import 'package:raabta/features/onboarding/presentation/welcome_screen.dart';
import 'package:raabta/core/services/service_locator.dart';
import 'package:raabta/core/services/notification_handler.dart';
import 'package:raabta/features/call/presentation/widgets/call_manager.dart';

/// A wrapper widget that handles authentication state changes
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstLaunch = true;
  bool _isCheckingFirstLaunch = true;
  late final UserProfileRepository _userProfileRepository;
  
  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _checkFirstLaunch();
  }

  /// Initialize repositories with error handling
  void _initializeRepositories() {
    try {
      if (kDebugMode) {
        log('🔐 AuthWrapper: Initializing repositories...');
      }
      
      // For user profile repository, check if services are initialized
      if (ServiceLocator().isInitialized) {
        _userProfileRepository = ServiceLocator().userProfileRepository;
        if (kDebugMode) {
          log('🔐 Using UserProfileRepository from ServiceLocator');
        }
      } else {
        // Create instance directly if ServiceLocator is not ready
        _userProfileRepository = FirebaseUserProfileRepository();
        if (kDebugMode) {
          log('ℹ️ Creating UserProfileRepository directly due to uninitialized services');
        }
      }
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('🚨 AuthWrapper initialization error: $e');
        log('🔍 Stack trace: $stackTrace');
      }
      
      // Fallback to direct initialization
      _userProfileRepository = FirebaseUserProfileRepository();
    }
  }

  Future<void> _checkFirstLaunch() async {
    try {
      if (kDebugMode) {
        log('🔍 Checking first launch status...');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      
      if (kDebugMode) {
        log('🔍 First launch status: $isFirstLaunch');
      }
      
      if (mounted) {
        setState(() {
          _isFirstLaunch = isFirstLaunch;
          _isCheckingFirstLaunch = false;
        });
      }
      
      // If this is first launch, mark it as false for next time
      if (isFirstLaunch) {
        await prefs.setBool('is_first_launch', false);
        if (kDebugMode) {
          log('✅ Marked first launch as complete');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('🚨 Error checking first launch: $e');
      }
      // Default to showing welcome screen if error
      if (mounted) {
        setState(() {
          _isFirstLaunch = true;
          _isCheckingFirstLaunch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      log('🔐 Building AuthWrapper');
    }

    // Show loading while checking first launch
    if (_isCheckingFirstLaunch) {
      return const SplashScreen(
        message: 'Initializing Raabta...',
        subtitle: 'Setting up your experience',
      );
    }

    // Show welcome screen for first-time users
    if (_isFirstLaunch) {
      if (kDebugMode) {
        log('🎉 First launch detected, showing welcome screen');
      }
      return const WelcomeScreen();
    }

    // Main authentication flow with StreamBuilder
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (kDebugMode) {
          log('🔐 Auth state change: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data?.uid ?? 'null'}');
        }

        // Handle all 4 cases as specified:

        // Case a: ConnectionState.waiting → show SplashScreen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(
            message: 'Connecting...',
            subtitle: 'Checking authentication status',
          );
        }

        // Case b: snapshot.hasError → show ErrorScreen
        if (snapshot.hasError) {
          if (kDebugMode) {
            log('🚨 Auth stream error: ${snapshot.error}');
          }
          return ErrorScreen(
            title: 'Authentication Error',
            message: 'Failed to connect to authentication services. Please check your internet connection and try again.',
            onRetry: () {
              // Retry by refreshing the auth state
              setState(() {
                // This will trigger a rebuild and restart the StreamBuilder
              });
            },
          );
        }

        // Case c: snapshot.hasData → user is authenticated, show HomeScreen (after profile check)
        if (snapshot.hasData) {
          final user = snapshot.data!;
          
          if (kDebugMode) {
            log('🔐 User is signed in: ${user.uid}');
          }
          
          // Check if user profile exists and is complete
          return FutureBuilder(
            future: _userProfileRepository.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (kDebugMode) {
                log('🔐 Profile check: ${profileSnapshot.connectionState}, hasData: ${profileSnapshot.hasData}');
              }

              if (profileSnapshot.hasError) {
                if (kDebugMode) {
                  log('🚨 Profile fetch error: ${profileSnapshot.error}');
                }
                return ErrorScreen(
                  title: 'Profile Error',
                  message: 'Failed to load user profile. Please try again.',
                  onRetry: () {
                    setState(() {
                      // This will trigger a rebuild and restart the profile check
                    });
                  },
                );
              }
              
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) {
                  log('🔐 Loading user profile...');
                }
                return const SplashScreen(
                  message: 'Loading Profile...',
                  subtitle: 'Getting your information ready',
                );
              }
              
              final profile = profileSnapshot.data;
              if (profile != null && profile.isProfileComplete) {
                if (kDebugMode) {
                  log('🔐 Profile is complete, showing home screen');
                }
                
                // Update FCM token for signed-in user
                _updateFCMTokenForUser(user.uid);
                
                // Profile is complete, show home screen
                return const CallManager(child: HomeScreen());
              } else {
                if (kDebugMode) {
                  log('🔐 Profile incomplete or missing, showing profile setup');
                }
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
                      if (createSnapshot.hasError) {
                        if (kDebugMode) {
                          log('🚨 Profile creation error: ${createSnapshot.error}');
                        }
                        return ErrorScreen(
                          title: 'Profile Creation Error',
                          message: 'Failed to create user profile. Please try signing in again.',
                          onRetry: () {
                            // Sign out and go back to login
                            FirebaseAuth.instance.signOut();
                          },
                        );
                      }
                      
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        if (kDebugMode) {
                          log('🔐 Creating initial profile...');
                        }
                        return const SplashScreen(
                          message: 'Setting up Profile...',
                          subtitle: 'Creating your account details',
                        );
                      }
                      
                      if (createSnapshot.hasData) {
                        if (kDebugMode) {
                          log('🔐 Initial profile created, showing setup screen');
                        }
                        return ProfileSetupScreen(initialProfile: createSnapshot.data!);
                      } else {
                        if (kDebugMode) {
                          log('🚨 Failed to create initial profile, signing out');
                        }
                        // Error creating profile, show sign in
                        return const SignInScreen();
                      }
                    },
                  );
                }
              }
            },
          );
        }

        // Case d: else → user is not authenticated, show LoginScreen
        if (kDebugMode) {
          log('🔐 User is not signed in, showing login screen');
        }
        
        // Remove FCM token when user signs out
        _handleUserSignOut();
        
        return const SignInScreen();
      },
    );
  }

  /// Update FCM token when user signs in
  void _updateFCMTokenForUser(String userId) {
    NotificationHandler().updateFCMTokenForUser(userId).catchError((error) {
      if (kDebugMode) {
        log('❌ Failed to update FCM token for user $userId: $error');
      }
    });
  }

  /// Handle user sign out - remove FCM token
  void _handleUserSignOut() {
    // Note: We can't get the user ID here since user is null
    // FCM token cleanup will happen during next sign-in
    // This is a limitation but acceptable since tokens have expiry
    if (kDebugMode) {
      log('🔐 User signed out, FCM token will be cleaned up on next sign-in');
    }
  }
}
