import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_options.dart';
// Import Agora platform view fix for web platform
import 'agora_web_stub_fix.dart';
import 'core/platform/agora_platform_view_fix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize Agora platform view fix for web compatibility
    try {
      debugPrint('🎥 Initializing Agora platform view fix for web...');
      initializeAgoraWebStubFix();
      AgoraPlatformViewFix.initialize();
      debugPrint('✅ Agora platform view fix initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Agora platform view fix initialization failed: $e');
      // Continue - the fix provides graceful fallbacks
    }
    
    // agora_uikit now works with proper web compatibility
    debugPrint('✅ Using agora_uikit for cross-platform compatibility');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
  runApp(const MyWebApp());
}

class MyWebApp extends StatelessWidget {
  const MyWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raabta - Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WebChatScreen(),
    );
  }
}

class WebChatScreen extends StatelessWidget {
  const WebChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raabta - Web'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Raabta Web!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Cross-platform calling powered by Agora UIKit',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}