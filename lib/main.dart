import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'core/services/service_locator.dart';
import 'core/services/logging_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_handler.dart';
import 'features/auth/presentation/auth_wrapper.dart';

void main() async {
  // Add error handling and logging
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    if (kDebugMode) {
      print('🚀 Starting Raabta app...');
      print('🌍 Platform: ${kIsWeb ? 'Web' : 'Native'}');
      print('🔧 Debug mode: $kDebugMode');
    }

    // Set up Flutter error handling first
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('🚨 Flutter Error: ${details.exception}');
        print('🔍 Library: ${details.library}');
        print('🔍 Context: ${details.context}');
        print('🔍 Stack Trace: ${details.stack}');
      }
    };

    // Initialize services with faster initialization for web
    bool servicesInitialized = false;
    try {
      if (kDebugMode) {
        print('⚙️ Initializing services...');
      }
      
      // Add timeout for service initialization to prevent hanging
      await ServiceLocator().initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Service initialization timeout - continuing with partial services');
          }
          throw TimeoutException('Service initialization timeout', const Duration(seconds: 15));
        },
      );
      servicesInitialized = true;
      
      if (kDebugMode) {
        print('✅ Services initialized successfully');
        final firebaseService = ServiceLocator().backendServiceOrNull;
        if (firebaseService?.isInitialized == true) {
          print('🔥 Firebase service is ready');
        }
      }
    } catch (serviceError, serviceStackTrace) {
      if (kDebugMode) {
        print('🚨 Service initialization error: $serviceError');
        print('🔍 Service Stack Trace: $serviceStackTrace');
      }
      
      // Continue without fully initialized services - the app can handle this
      LoggingService.warning('⚠️ Running in degraded mode due to service initialization failure');
    }

    runApp(MyApp(servicesInitialized: servicesInitialized));
    
    if (kDebugMode) {
      print('✅ App started successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Critical error starting app: $e');
      print('🔍 Stack Trace: $stackTrace');
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
                      color: Colors.white.withOpacity( 0.2),
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
                      'We encountered an error while starting the app. This might be due to a network issue or browser compatibility.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity( 0.9),
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
                        color: Colors.black.withOpacity( 0.3),
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
                            // For web, reload the page
                            LoggingService.info('🔄 Reloading page...');
                            // Would need dart:html import for window.location.reload()
                          } else {
                            // For mobile, try to restart main
                            main();
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[600],
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

class MyApp extends StatelessWidget {
  final bool servicesInitialized;
  
  const MyApp({super.key, this.servicesInitialized = true});

  // Global navigator key for error dialogs
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🏗️ Building MyApp widget');
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
                cardTheme: const CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
      ),
      home: SafeArea(
        child: AuthWrapper(servicesInitialized: servicesInitialized),
      ),
      // Enhanced error builder for better error handling
      builder: (context, widget) {
        // Handle widget errors gracefully
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          if (kDebugMode) {
            print('🚨 Widget Error: ${errorDetails.exception}');
            print('🔍 Widget Error Library: ${errorDetails.library}');
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
                              child: AuthWrapper(servicesInitialized: true),
                            ),
                          ),
                        );
                      } catch (e) {
                        // If navigation fails, show the auth wrapper directly
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SafeArea(
                              child: AuthWrapper(servicesInitialized: true),
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
