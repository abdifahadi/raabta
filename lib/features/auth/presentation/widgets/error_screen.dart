import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../sign_in_screen.dart';

/// Error screen component for error states
class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  
  const ErrorScreen({
    super.key,
    this.title,
    this.message,
    this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Log the actual error details for debugging
    if (error != null) {
      if (kDebugMode) {
        log('🚨 ErrorScreen - Error: $error');
        if (stackTrace != null) {
          log('🚨 ErrorScreen - Stack Trace: $stackTrace');
        }
      }
    }

    // Determine appropriate error message based on error type
    String errorMessage = message ?? _getDefaultMessage();
    
    // If we have a specific error, try to provide more helpful info
    if (error != null) {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errorStr.contains('firebase') || errorStr.contains('auth')) {
        errorMessage = 'Firebase authentication service is temporarily unavailable. Please try again in a moment.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'The request timed out. Please check your connection and try again.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
      }
    }

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
                  Text(
                    title ?? 'Authentication Error',
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
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  // Debug error details (only in debug mode)
                  if (kDebugMode && error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Information:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (stackTrace != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Stack Trace: ${stackTrace.toString().split('\n').take(3).join('\n')}...',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  // Action buttons
                  Column(
                    children: [
                      // Primary button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onRetry ?? () {
                            // Navigate to login screen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Retry'),
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
                      const SizedBox(height: 12),
                      // Secondary button for sign in
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text('Go to Sign In'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
  
  String _getDefaultMessage() {
    if (kIsWeb) {
      return 'We encountered an issue with authentication services on the web. This might be due to browser settings, network issues, or Firebase configuration problems.';
    } else {
      return 'We encountered an issue with authentication services. Please try again or contact support if the problem persists.';
    }
  }
}