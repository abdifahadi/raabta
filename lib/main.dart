import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/services/service_locator.dart';
import 'features/auth/presentation/auth_wrapper.dart';

void main() async {
  // Add error handling and logging
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (kDebugMode) {
      print('🚀 Starting Raabta app...');
    }

    // Initialize services with error handling
    await ServiceLocator().initialize();
    
    if (kDebugMode) {
      print('✅ Services initialized successfully');
    }

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('🚨 Flutter Error: ${details.exception}');
        print('🔍 Stack Trace: ${details.stack}');
      }
    };

    runApp(const MyApp());
    
    if (kDebugMode) {
      print('✅ App started successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Error starting app: $e');
      print('🔍 Stack Trace: $stackTrace');
    }
    
    // Still try to run the app with a fallback UI
    runApp(
      MaterialApp(
        home: Scaffold(
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
                  'App Failed to Initialize',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🏗️ Building MyApp widget');
    }
    
    return MaterialApp(
      title: 'Raabta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SafeArea(
        child: AuthWrapper(),
      ),
      // Add error builder for better error handling
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          if (kDebugMode) {
            print('🚨 Widget Error: ${errorDetails.exception}');
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
                    'Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (kDebugMode)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        errorDetails.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to reload the app
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SafeArea(
                            child: AuthWrapper(),
                          ),
                        ),
                      );
                    },
                    child: const Text('Retry'),
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
