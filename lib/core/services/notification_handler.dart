import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_payload.dart';
import 'service_locator.dart';

/// Handles notification interactions and navigation
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  StreamSubscription<NotificationPayload>? _notificationTapSubscription;
  StreamSubscription<NotificationPayload>? _foregroundMessageSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize notification handler with navigator key
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _setupNotificationListeners();
  }

  /// Set up notification listeners
  void _setupNotificationListeners() {
    final notificationService = ServiceLocator().notificationServiceOrNull;
    if (notificationService == null) return;

    // Listen for notification taps
    _notificationTapSubscription = notificationService.onNotificationTap.listen(
      _handleNotificationTap,
      onError: (error) {
        if (kDebugMode) {
          log('❌ Error handling notification tap: $error');
        }
      },
    );

    // Listen for foreground messages
    _foregroundMessageSubscription = notificationService.onForegroundMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        if (kDebugMode) {
          log('❌ Error handling foreground message: $error');
        }
      },
    );
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(NotificationPayload payload) {
    if (kDebugMode) {
      log('🔔 Handling notification tap: ${payload.toString()}');
    }

    final context = _navigatorKey?.currentContext;
    if (context == null) {
      if (kDebugMode) log('❌ Navigator context not available');
      return;
    }

    // Handle chat message notifications
    if (payload.isChatMessage && payload.conversationId != null) {
      _navigateToChatScreen(context, payload.conversationId!, payload.senderId);
    } else {
      // Handle other notification types
      if (kDebugMode) {
        log('🔔 Unhandled notification type: ${payload.type}');
      }
    }
  }

  /// Handle foreground messages - show in-app notification or update UI
  void _handleForegroundMessage(NotificationPayload payload) {
    if (kDebugMode) {
      log('🔔 Handling foreground message: ${payload.toString()}');
    }

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    // Check if user is currently in the same chat
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/chat' && payload.conversationId != null) {
      // User is in chat screen - check if it's the same conversation
      // You might want to pass conversation ID through route arguments
      // and compare here to decide whether to show notification or not
      return;
    }

    // Show in-app notification for foreground messages
    _showInAppNotification(context, payload);
  }

  /// Navigate to chat screen
  void _navigateToChatScreen(BuildContext context, String conversationId, String? otherUserId) {
    try {
      // Check if already on the same chat screen
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == '/chat') {
        // Check if it's the same conversation and return if so
        final currentArgs = ModalRoute.of(context)?.settings.arguments;
        if (currentArgs is Map<String, dynamic> && 
            currentArgs['conversationId'] == conversationId) {
          return; // Already on the same conversation
        }
        Navigator.of(context).pop(); // Pop current chat if different
      }

      // Navigate to chat screen
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'conversationId': conversationId,
          'otherUserId': otherUserId,
        },
      );

      if (kDebugMode) {
        log('✅ Navigated to chat screen: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error navigating to chat screen: $e');
      }
    }
  }

  /// Show in-app notification using SnackBar or custom widget
  void _showInAppNotification(BuildContext context, NotificationPayload payload) {
    if (payload.title == null && payload.body == null) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (payload.title != null)
                Text(
                  payload.title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (payload.body != null)
                Text(payload.body!),
            ],
          ),
          action: payload.conversationId != null
              ? SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    _navigateToChatScreen(context, payload.conversationId!, payload.senderId);
                  },
                )
              : null,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        log('❌ Error showing in-app notification: $e');
      }
    }
  }

  /// Update FCM token when user signs in
  Future<void> updateFCMTokenForUser(String userId) async {
    try {
      final notificationService = ServiceLocator().notificationServiceOrNull;
      final chatRepository = ServiceLocator().chatRepository;

      if (notificationService == null) {
        if (kDebugMode) log('❌ NotificationService not available');
        return;
      }

      final token = await notificationService.getFCMToken();
      if (token != null) {
        await chatRepository.saveFCMToken(userId, token);
        if (kDebugMode) log('✅ FCM token saved for user: $userId');
        
        // Clean up old tokens
        await chatRepository.cleanupOldFCMTokens(userId);
      }
    } catch (e) {
      if (kDebugMode) log('❌ Error updating FCM token: $e');
    }
  }

  /// Remove FCM token when user signs out
  Future<void> removeFCMTokenForUser(String userId) async {
    try {
      final notificationService = ServiceLocator().notificationServiceOrNull;
      final chatRepository = ServiceLocator().chatRepository;

      if (notificationService == null) return;

      final token = await notificationService.getFCMToken();
      if (token != null) {
        await chatRepository.removeFCMToken(userId, token);
        if (kDebugMode) log('✅ FCM token removed for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) log('❌ Error removing FCM token: $e');
    }
  }

  /// Subscribe to user-specific topic
  Future<void> subscribeToUserTopic(String userId) async {
    try {
      final notificationService = ServiceLocator().notificationServiceOrNull;
      if (notificationService == null) return;

      await notificationService.subscribeToTopic('user_$userId');
      if (kDebugMode) log('✅ Subscribed to user topic: user_$userId');
    } catch (e) {
      if (kDebugMode) log('❌ Error subscribing to user topic: $e');
    }
  }

  /// Unsubscribe from user-specific topic
  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      final notificationService = ServiceLocator().notificationServiceOrNull;
      if (notificationService == null) return;

      await notificationService.unsubscribeFromTopic('user_$userId');
      if (kDebugMode) log('✅ Unsubscribed from user topic: user_$userId');
    } catch (e) {
      if (kDebugMode) log('❌ Error unsubscribing from user topic: $e');
    }
  }

  /// Check and request notification permissions
  Future<bool> ensureNotificationPermissions() async {
    try {
      final notificationService = ServiceLocator().notificationServiceOrNull;
      if (notificationService == null) return false;

      final hasPermission = await notificationService.areNotificationsEnabled();
      if (!hasPermission) {
        return await notificationService.requestPermission();
      }
      return true;
    } catch (e) {
      if (kDebugMode) log('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _notificationTapSubscription = null;
    _foregroundMessageSubscription = null;
  }
}