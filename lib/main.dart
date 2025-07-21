import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'dart:developer';
import 'core/config/firebase_options.dart';
import 'core/services/service_locator.dart';
import 'core/services/logging_service.dart';

import 'core/services/notification_handler.dart';
import 'features/auth/presentation/auth_wrapper.dart';

/// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  if (kDebugMode) {
    log('📲 Background message received: ${message.messageId}');
  }
}

void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling and logging
  try {
    if (kDebugMode) {
      log('🚀 Starting Raabta app...');
      log('🌍 Platform: ${kIsWeb ? 'Web' : 'Native'}');
      log('🔧 Debug mode: $kDebugMode');
    }

    // Initialize Firebase first with proper error handling
    try {
      if (kDebugMode) {
        log('🔥 Initializing Firebase...');
        log('🌍 Platform detected: ${kIsWeb ? 'Web' : 'Native'}');
        log('🔧 Using Firebase options for current platform');
      }
      
      // Add timeout for Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15),
        onTimeout: () {
          if (kDebugMode) {
            log('⏰ Firebase initialization timeout');
          }
          throw TimeoutException('Firebase initialization timeout', kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15));
        },
      );
      
      if (kDebugMode) {
        log('✅ Firebase initialized successfully');
        
        // Verify Firebase app is working
        final app = Firebase.app();
        log('✅ Firebase app verified: ${app.name} - Project: ${app.options.projectId}');
        
        if (kIsWeb) {
          log('🌐 Web Firebase config:');
          log('  - Auth Domain: ${app.options.authDomain}');
          log('  - Storage Bucket: ${app.options.storageBucket}');
          log('  - API Key Length: ${app.options.apiKey.length} chars');
        }
      }
    } catch (firebaseError, firebaseStackTrace) {
      if (kDebugMode) {
        log('❌ Firebase initialization failed: $firebaseError');
        log('🔍 Firebase Stack Trace: $firebaseStackTrace');
        
        // Additional debugging for web
        if (kIsWeb) {
          log('🌐 Web-specific debugging:');
          log('  - Check if Firebase scripts are loaded in index.html');
          log('  - Verify network connectivity');
          log('  - Check browser console for additional errors');
        }
      }
      
      // Log the error but don't stop the app - some features might still work
      LoggingService.error('Firebase initialization failed: $firebaseError');
      
      // Continue with app initialization in degraded mode
    }
    
    // Set up FCM background message handler (skip on web)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        log('🚨 Flutter Error: ${details.exception}');
        log('🔍 Library: ${details.library}');
        log('🔍 Context: ${details.context}');
        log('🔍 Stack Trace: ${details.stack}');
      }
    };

    // Initialize services with setupLocator function
    bool servicesInitialized = false;
    try {
      if (kDebugMode) {
        log('⚙️ Setting up services...');
      }
      
      // Use setupLocator function
      await setupLocator();
      servicesInitialized = true;
      
      if (kDebugMode) {
        log('✅ Services setup completed successfully');
      }
    } catch (serviceError, serviceStackTrace) {
      if (kDebugMode) {
        log('🚨 Service setup error: $serviceError');
        log('🔍 Service Stack Trace: $serviceStackTrace');
      }
      
      // Continue without fully initialized services - the app can handle this
      LoggingService.warning('⚠️ Running in degraded mode due to service setup failure');
      
      // For web, add additional fallback delay to ensure DOM is ready
      if (kIsWeb) {
        if (kDebugMode) {
          log('🌐 Web platform: Adding fallback delay for DOM readiness');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Add a small delay for web to ensure all scripts are loaded
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Start the app
    runApp(MyApp(servicesInitialized: servicesInitialized));
    
    if (kDebugMode) {
      log('✅ App started successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      log('❌ Critical error starting app: $e');
      log('🔍 Stack Trace: $stackTrace');
    }
    
    // Still try to run the app with a fallback UI
    runApp(
      MaterialApp(
        title: 'Raabta - Error',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'App Failed to Initialize',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      kIsWeb 
                        ? 'We encountered an error while starting the web app. This might be due to a network issue or browser compatibility. Please refresh the page to try again.'
                        : 'We encountered an error while starting the app. This might be due to a network issue or device compatibility.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (kDebugMode)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Debug Error: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Try to restart the app
                          if (kIsWeb) {
                            // For web, show a message that they need to refresh
                            LoggingService.info('🔄 Please refresh the page to retry...');
                          } else {
                            // For mobile, try to restart main
                            main();
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        // Note: Cannot use const here due to conditional expression
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
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
}

/// Setup function for service locator
Future<void> setupLocator() async {
  try {
    // Reduced timeout for web platforms
    const timeout = kIsWeb ? Duration(seconds: 5) : Duration(seconds: 10);
    
    await ServiceLocator().initialize().timeout(
      timeout,
      onTimeout: () {
        if (kDebugMode) {
          log('⚠️ Service initialization timeout (${timeout.inSeconds}s) - continuing with degraded mode');
        }
        throw TimeoutException('Service initialization timeout', timeout);
      },
    );
    
    if (kDebugMode) {
      log('✅ ServiceLocator setup completed');
    }
  } catch (e) {
    if (kDebugMode) {
      log('❌ ServiceLocator setup failed: $e');
    }
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final bool servicesInitialized;
  
  const MyApp({super.key, this.servicesInitialized = true});

  // Global navigator key for error dialogs
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      log('🏗️ Building MyApp widget');
    }
    
    // Initialize notification handler with navigator key
    NotificationHandler().initialize(navigatorKey);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Raabta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        // Improve visual design
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const SafeArea(
        child: AuthWrapper(),
      ),
      // Enhanced error builder for better error handling
      builder: (context, widget) {
        // Handle widget errors gracefully
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          if (kDebugMode) {
            log('🚨 Widget Error: ${errorDetails.exception}');
            log('🔍 Widget Error Library: ${errorDetails.library}');
          }
          return Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We encountered a display issue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  if (kDebugMode)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorDetails.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Try to reload the current route
                      try {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SafeArea(
                              child: AuthWrapper(),
                            ),
                          ),
                        );
                      } catch (e) {
                        // If navigation fails, show the auth wrapper directly
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SafeArea(
                              child: AuthWrapper(),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        };
        
        return widget ?? const SizedBox.shrink();
      },
    );
  }
}
