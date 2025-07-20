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
  final bool servicesInitialized;
  
  const AuthWrapper({super.key, this.servicesInitialized = true});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasTimeout = false;
  bool _isRetrying = false;
  bool _isFirstLaunch = true;
  bool _isCheckingFirstLaunch = true;
  bool _hasInitializationError = false;
  String _errorMessage = '';
  late final AuthRepository _authRepository;
  late final UserProfileRepository _userProfileRepository;
  
  @override
  void initState() {
    super.initState();
    
    _initializeRepositories();
  }

  /// Initialize repositories with error handling
  void _initializeRepositories() {
    try {
      // Initialize repositories safely
      _authRepository = FirebaseAuthRepository();
      
      // For user profile repository, check if services are initialized
      if (widget.servicesInitialized && ServiceLocator().isInitialized) {
        _userProfileRepository = ServiceLocator().userProfileRepository;
      } else {
        // Create instance directly if ServiceLocator is not ready
        _userProfileRepository = FirebaseUserProfileRepository();
        if (kDebugMode) {
          print('ℹ️ Creating UserProfileRepository directly due to uninitialized services');
        }
      }
      
      // Check if this is first launch
      _checkFirstLaunch();
      
      // Reduced timeout for better UX (from 8 seconds to 5 seconds)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_isRetrying) {
          setState(() {
            _hasTimeout = true;
          });
        }
      });
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🚨 AuthWrapper initialization error: $e');
        print('🔍 Stack trace: $stackTrace');
      }
      
      setState(() {
        _hasInitializationError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      
      if (kDebugMode) {
        print('🔍 Checking first launch: $isFirstLaunch');
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error checking first launch: $e');
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

  void _retry() {
    setState(() {
      _hasTimeout = false;
      _isRetrying = true;
    });
    
    // Reset retry flag after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
    
    // Add timeout again
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_isRetrying) {
        setState(() {
          _hasTimeout = true;
        });
      }
    });
  }

  Widget _buildLoadingScreen({
    required String title,
    required String subtitle,
    Color? backgroundColor,
  }) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundColor != null 
              ? [backgroundColor, backgroundColor.withValues(alpha: 0.8)]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
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
                  child: Text(
                    title,
                    style: const TextStyle(
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
                    subtitle,
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

  Widget _buildErrorScreen({
    required String title,
    required String message,
    required VoidCallback onRetry,
    VoidCallback? onSignIn,
  }) {
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
                      Icons.wifi_off,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
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
                      message,
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
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Try Again'),
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
                      if (onSignIn != null) ...[
                        const SizedBox(height: 12),
                        // Secondary button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onSignIn,
                            icon: const Icon(Icons.login, size: 20),
                            label: const Text('Go to Sign In'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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
      print('🔐 Building AuthWrapper');
    }

    // Show initialization error screen if repositories failed to initialize
    if (_hasInitializationError) {
      return _buildErrorScreen(
        title: 'Initialization Error',
        message: _errorMessage,
        onRetry: () {
          _initializeRepositories(); // Retry initialization
        },
        onSignIn: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SignInScreen(),
            ),
          );
        },
      );
    }

    // Show loading while checking first launch
    if (_isCheckingFirstLaunch) {
      return _buildLoadingScreen(
        title: 'Loading Raabta...',
        subtitle: 'Please wait while we set things up',
      );
    }

    // Show welcome screen for first-time users
    if (_isFirstLaunch) {
      if (kDebugMode) {
        print('🎉 First launch detected, showing welcome screen');
      }
      return const WelcomeScreen();
    }

    // Show timeout message if loading takes too long
    if (_hasTimeout) {
      return _buildErrorScreen(
        title: 'Connection Timeout',
        message: 'Loading is taking longer than expected. Please check your internet connection and try again.',
        onRetry: _retry,
        onSignIn: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SignInScreen(),
            ),
          );
        },
      );
    }

    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (kDebugMode) {
          print('🔐 Auth state change: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data}');
        }

        // Handle errors
        if (snapshot.hasError) {
          if (kDebugMode) {
            print('🚨 Auth stream error: ${snapshot.error}');
          }
          return _buildErrorScreen(
            title: 'Authentication Error',
            message: 'We encountered an issue with authentication services. Please try again or contact support if the problem persists.',
            onRetry: () {
              _authRepository.signOut();
              _retry();
            },
            onSignIn: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SignInScreen(),
                ),
              );
            },
          );
        }

        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) {
            print('🔐 Waiting for auth state...');
          }
          return _buildLoadingScreen(
            title: 'Checking authentication...',
            subtitle: 'Please wait a moment',
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
            future: _userProfileRepository.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (kDebugMode) {
                print('🔐 Profile check: ${profileSnapshot.connectionState}, hasData: ${profileSnapshot.hasData}');
              }

              if (profileSnapshot.hasError) {
                if (kDebugMode) {
                  print('🚨 Profile fetch error: ${profileSnapshot.error}');
                }
                return _buildErrorScreen(
                  title: 'Profile Loading Error',
                  message: 'We couldn\'t load your profile. This might be a temporary issue with our servers.',
                  onRetry: () {
                    setState(() {
                      // Trigger rebuild to retry profile loading
                    });
                  },
                  onSignIn: () {
                    _authRepository.signOut();
                  },
                );
              }
              
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) {
                  print('🔐 Loading user profile...');
                }
                return _buildLoadingScreen(
                  title: 'Loading profile...',
                  subtitle: 'Setting up your account',
                );
              }
              
              final profile = profileSnapshot.data;
              if (profile != null && profile.isProfileComplete) {
                if (kDebugMode) {
                  print('🔐 Profile is complete, showing home screen');
                }
                
                // Update FCM token for signed-in user
                _updateFCMTokenForUser(user.uid);
                
                // Profile is complete, show home with smooth transition
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, opacity, child) => Opacity(
                    opacity: opacity,
                    child: const CallManager(child: HomeScreen()),
                  ),
                );
              } else {
                if (kDebugMode) {
                  print('🔐 Profile incomplete or missing, showing profile setup');
                }
                // Profile doesn't exist or is incomplete, show profile setup
                if (profile != null) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, opacity, child) => Opacity(
                      opacity: opacity,
                      child: ProfileSetupScreen(initialProfile: profile),
                    ),
                  );
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
                          print('🚨 Profile creation error: ${createSnapshot.error}');
                        }
                        return _buildErrorScreen(
                          title: 'Profile Creation Error',
                          message: 'We couldn\'t create your profile. Please try signing in again.',
                          onRetry: () {
                            _authRepository.signOut();
                          },
                        );
                      }
                      
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        if (kDebugMode) {
                          print('🔐 Creating initial profile...');
                        }
                        return _buildLoadingScreen(
                          title: 'Setting up profile...',
                          subtitle: 'Almost ready!',
                        );
                      }
                      
                      if (createSnapshot.hasData) {
                        if (kDebugMode) {
                          print('🔐 Initial profile created, showing setup screen');
                        }
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, opacity, child) => Opacity(
                            opacity: opacity,
                            child: ProfileSetupScreen(initialProfile: createSnapshot.data!),
                          ),
                        );
                      } else {
                        if (kDebugMode) {
                          print('🚨 Failed to create initial profile, signing out');
                        }
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
        if (kDebugMode) {
          print('🔐 User is not signed in, showing sign in screen');
        }
        
        // Remove FCM token when user signs out
        _handleUserSignOut();
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, opacity, child) => Opacity(
            opacity: opacity,
            child: const SignInScreen(),
          ),
        );
      },
    );
  }

  /// Update FCM token when user signs in
  void _updateFCMTokenForUser(String userId) {
    NotificationHandler().updateFCMTokenForUser(userId).catchError((error) {
      if (kDebugMode) {
        print('❌ Failed to update FCM token for user $userId: $error');
      }
    });
  }

  /// Handle user sign out - remove FCM token
  void _handleUserSignOut() {
    // Note: We can't get the user ID here since user is null
    // FCM token cleanup will happen during next sign-in
    // This is a limitation but acceptable since tokens have expiry
    if (kDebugMode) {
      print('🔐 User signed out, FCM token will be cleaned up on next sign-in');
    }
  }
}
