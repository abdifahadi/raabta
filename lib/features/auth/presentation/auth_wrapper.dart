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

  /// Splash screen component for loading states
  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Loading spinner with custom animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, opacity, child) => Opacity(
                  opacity: opacity,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title with fade-in animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                builder: (context, opacity, child) => Opacity(
                  opacity: opacity,
                  child: const Text(
                    'Loading Raabta...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle with delayed fade-in
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1400),
                builder: (context, opacity, child) => Opacity(
                  opacity: opacity,
                  child: Text(
                    'Please wait while we set things up',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error screen component for error states
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Authentication Error',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Container(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Text(
                      kIsWeb 
                        ? 'We encountered an issue with authentication services on the web. This might be due to browser settings or network issues.'
                        : 'We encountered an issue with authentication services. Please try again or contact support if the problem persists.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  Column(
                    children: [
                      // Primary button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to login screen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text('Go to Sign In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      log('🔐 Building AuthWrapper');
    }

    // Show loading while checking first launch
    if (_isCheckingFirstLaunch) {
      return _buildSplashScreen();
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

        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        } 
        // Show error screen if there's an error
        else if (snapshot.hasError) {
          if (kDebugMode) {
            log('🚨 Auth stream error: ${snapshot.error}');
          }
          return _buildErrorScreen();
        } 
        // Show login screen if user is not authenticated
        else if (!snapshot.hasData) {
          if (kDebugMode) {
            log('🔐 User is not signed in, showing login screen');
          }
          
          // Remove FCM token when user signs out
          _handleUserSignOut();
          
          return const SignInScreen();
        } 
        // User is authenticated, check profile and show home screen
        else {
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
                return _buildErrorScreen();
              }
              
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) {
                  log('🔐 Loading user profile...');
                }
                return _buildSplashScreen();
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
                        return _buildErrorScreen();
                      }
                      
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        if (kDebugMode) {
                          log('🔐 Creating initial profile...');
                        }
                        return _buildSplashScreen();
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
