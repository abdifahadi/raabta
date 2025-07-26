import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/firebase_options.dart';
import 'core/services/service_locator.dart';
import 'core/services/logging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import required classes
import 'core/services/notification_handler.dart';
import 'features/auth/presentation/auth_wrapper.dart';
import 'features/call/presentation/screens/call_screen.dart';
import 'features/call/presentation/screens/incoming_call_screen.dart';
import 'features/call/presentation/screens/call_test_screen.dart';
import 'features/call/domain/models/call_model.dart';

/// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized before handling background messages
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  
  if (kDebugMode) {
    log('📲 Background message received: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    log('🚀 Raabta: Starting application...');
    log('🌍 Platform: ${kIsWeb ? 'Web' : 'Native'}');
  }

  bool servicesInitialized = false;
  
  try {
    // Firebase setup with proper error handling and single initialization
    if (kDebugMode) {
      log('🔥 Firebase: Checking initialization status...');
      log('🌍 Platform detected: ${kIsWeb ? 'Web' : 'Native'}');
    }
    
    // ✅ FIREBASE FIX: Only initialize if no apps exist
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        log('🔥 Firebase: Initializing for the first time...');
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15),
        onTimeout: () {
          if (kDebugMode) log('⏰ Firebase: Initialization timeout');
          throw TimeoutException('Firebase initialization timeout', kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15));
        },
      );
      if (kDebugMode) {
        log('✅ Firebase: Initialized successfully');
      }
    } else {
      if (kDebugMode) {
        log('✅ Firebase: Already initialized, using existing instance');
      }
    }

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Setup ServiceLocator with dependency injection
    // Note: Agora services are disabled on Web platform
    if (kIsWeb) {
      if (kDebugMode) {
        log('🌐 Web platform: Agora video calling disabled');
        log('📱 For video calls, users should use mobile/desktop apps');
      }
    }

    try {
      if (kDebugMode) {
        log('🔧 ServiceLocator: Setting up services...');
      }
      await setupLocator();
      servicesInitialized = true;
      if (kDebugMode) {
        log('✅ ServiceLocator: All services initialized successfully');
      }
    } catch (serviceError) {
      servicesInitialized = false;
      
      // Web platform specific handling
      if (kIsWeb) {
        if (kDebugMode) {
          log('🌐 Web platform: Service initialization with limited features');
        }
        // Continue with basic services only
        servicesInitialized = true;
      } else {
        // Non-web platforms require full service initialization
        if (kDebugMode) {
          log('❌ Native platform: Service initialization failed: $serviceError');
        }
      }
      
      // This is critical - don't continue without initialized services
      LoggingService.error('❌ ServiceLocator initialization failed: $serviceError');
      
      // For web, add additional fallback delay to ensure DOM is ready
      if (kIsWeb) {
        if (kDebugMode) {
          log('🌐 Web platform: Adding fallback delay for DOM readiness');
        }
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try one more time for web
        try {
          if (kDebugMode) {
            log('🔄 Retrying ServiceLocator initialization for web...');
          }
          await setupLocator();
          servicesInitialized = true;
          if (kDebugMode) {
            log('✅ ServiceLocator setup succeeded on retry');
          }
        } catch (retryError) {
          if (kDebugMode) {
            log('❌ ServiceLocator retry failed: $retryError');
          }
          // Continue with degraded mode
        }
      }
    }

    // Verify ServiceLocator is properly initialized before starting the app
    if (servicesInitialized && ServiceLocator().isInitialized) {
      if (kDebugMode) {
        log('✅ ServiceLocator verification passed - all services ready');
      }
    } else {
      if (kDebugMode) {
        log('⚠️ ServiceLocator not fully initialized - app will run in degraded mode');
      }
    }

    // Add a small delay for web to ensure all scripts are loaded
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Start the app with proper service initialization status
    runApp(MyApp(servicesInitialized: servicesInitialized));
    
    if (kDebugMode) {
      log('✅ App started successfully with ${servicesInitialized ? 'full' : 'degraded'} services');
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
                      color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.9),
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
                        color: Colors.black.withOpacity(0.3),
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
    if (kDebugMode) {
      log('🔧 Starting ServiceLocator initialization...');
    }
    
    // Reduced timeout for web platforms
    const timeout = kIsWeb ? Duration(seconds: 8) : Duration(seconds: 15);
    
    await ServiceLocator().initialize().timeout(
      timeout,
      onTimeout: () {
        if (kDebugMode) {
          log('⚠️ ServiceLocator initialization timeout (${timeout.inSeconds}s)');
        }
        throw TimeoutException('Service initialization timeout', timeout);
      },
    );
    
    if (kDebugMode) {
      log('✅ ServiceLocator setup completed successfully');
      log('✅ All dependencies are ready for use');
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
    
    // ✅ FULLSCREEN FIX: Configure system UI overlays for fullscreen experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Set system UI overlay style for transparent status/navigation bars
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
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
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        cardTheme: CardTheme.of(context).copyWith(
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      // ✅ FULLSCREEN FIX: Use Scaffold instead of SafeArea for root to handle system UI properly
      home: Scaffold(
        body: SafeArea(
          // Allow the app to extend into system UI areas when needed
          top: false,
          bottom: false,
          child: Container(
            // Ensure the container takes full screen space
            width: double.infinity,
            height: double.infinity,
            child: const AuthWrapper(),
          ),
        ),
      ),
      routes: {
        '/call': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args != null && args is CallModel) {
            return Scaffold(
              body: SafeArea(
                top: false,
                bottom: false,
                child: CallScreen(call: args),
              ),
            );
          }
          // If no arguments or wrong type, return to home
          return Scaffold(
            body: SafeArea(
              top: false,
              bottom: false,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: const AuthWrapper(),
              ),
            ),
          );
        },
        '/incoming-call': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args != null && args is CallModel) {
            return Scaffold(
              body: SafeArea(
                top: false,
                bottom: false,
                child: IncomingCallScreen(call: args),
              ),
            );
          }
          // If no arguments or wrong type, return to home
          return Scaffold(
            body: SafeArea(
              top: false,
              bottom: false,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: const AuthWrapper(),
              ),
            ),
          );
        },
        '/call-test': (context) => Scaffold(
          body: SafeArea(
            top: false,
            bottom: false,
            child: const CallTestScreen(),
          ),
        ),
      },
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
                            builder: (context) => Scaffold(
                              body: SafeArea(
                                top: false,
                                bottom: false,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: const AuthWrapper(),
                                ),
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        // If navigation fails, show the auth wrapper directly
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              body: SafeArea(
                                top: false,
                                bottom: false,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: const AuthWrapper(),
                                ),
                              ),
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
