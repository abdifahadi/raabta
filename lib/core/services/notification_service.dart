import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_payload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raabta/core/services/service_locator.dart';

/// Abstract interface for notification services
abstract class NotificationServiceInterface {
  Future<void> initialize();
  Future<String?> getFCMToken();
  Future<bool> requestPermission();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Stream<NotificationPayload> get onNotificationTap;
  Stream<NotificationPayload> get onForegroundMessage;
  Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationPayload? payload,
  });
}

/// FCM Notification Service implementation
class NotificationService implements NotificationServiceInterface {
  static const String _channelId = 'raabta_messages';
  static const String _channelName = 'Raabta Messages';
  static const String _channelDescription = 'Notifications for new messages in Raabta';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controllers for notification events
  final StreamController<NotificationPayload> _onNotificationTapController = 
      StreamController<NotificationPayload>.broadcast();
  final StreamController<NotificationPayload> _onForegroundMessageController = 
      StreamController<NotificationPayload>.broadcast();

  bool _isInitialized = false;
  String? _currentToken;

  @override
  Stream<NotificationPayload> get onNotificationTap => _onNotificationTapController.stream;

  @override
  Stream<NotificationPayload> get onForegroundMessage => _onForegroundMessageController.stream;

  /// Initialize the notification service
  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) log('🔔 NotificationService already initialized');
      return;
    }

    try {
      if (kDebugMode) log('🔔 Initializing NotificationService...');

      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permissions
      await requestPermission();

      // Get initial FCM token
      _currentToken = await _firebaseMessaging.getToken();
      if (kDebugMode) log('🔑 FCM Token: $_currentToken');

      // Set up FCM message handlers
      await _setupFCMHandlers();

      // Handle notification taps when app is terminated
      await _handleInitialMessage();

      _isInitialized = true;
      if (kDebugMode) log('✅ NotificationService initialized successfully');
    } catch (e) {
      if (kDebugMode) log('❌ NotificationService initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // macOS initialization
    const DarwinInitializationSettings macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux initialization (basic support)
    const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Set up FCM message handlers
  Future<void> _setupFCMHandlers() async {
    // ✅ NOTIFICATION FIX: Handle foreground messages with proper local notification display
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        log('🔔 Received foreground message: ${message.messageId}');
        log('📱 Title: ${message.notification?.title}');
        log('📱 Body: ${message.notification?.body}');
        log('📱 Data: ${message.data}');
      }

      final payload = _createNotificationPayload(message);
      _onForegroundMessageController.add(payload);

      // ✅ Always show local notification for foreground messages
      _showLocalNotificationFromRemote(message);
    });

    // ✅ NOTIFICATION FIX: Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        log('🔔 App opened from background notification: ${message.messageId}');
        log('📱 Message data: ${message.data}');
      }

      final payload = _createNotificationPayload(message);
      // Add slight delay to ensure app is ready to handle navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _onNotificationTapController.add(payload);
      });
    });

    // ✅ NOTIFICATION FIX: Handle token refresh with better error handling
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) log('🔄 FCM Token refreshed: $token');
      _currentToken = token;
      // Update token in Firestore when user is available
      _updateTokenInFirestore(token);
    });

    // ✅ NOTIFICATION FIX: Set up notification interaction handling
    _setupNotificationInteraction();
  }

  /// ✅ NOTIFICATION FIX: Setup notification interaction handlers
  Future<void> _setupNotificationInteraction() async {
    // Configure notification tap action for Android
    if (!kIsWeb) {
      // Set up notification action handlers
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Handle initial message when app is opened from terminated state
  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        log('🔔 App opened from terminated state with notification: ${initialMessage.messageId}');
        log('📱 Initial message data: ${initialMessage.data}');
      }

      final payload = _createNotificationPayload(initialMessage);
      // ✅ NOTIFICATION FIX: Delay to ensure app is fully initialized before handling navigation
      Future.delayed(const Duration(seconds: 2), () {
        _onNotificationTapController.add(payload);
      });
    }
  }

  /// Handle local notification taps
  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      log('🔔 Local notification tapped: ${response.id}');
      log('📱 Payload: ${response.payload}');
    }

    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        final payload = NotificationPayload.fromMap(data);
        _onNotificationTapController.add(payload);
      } catch (e) {
        if (kDebugMode) log('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Create NotificationPayload from RemoteMessage
  NotificationPayload _createNotificationPayload(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    
    // Add notification title and body to data if available
    if (message.notification?.title != null) {
      data['title'] = message.notification!.title!;
    }
    if (message.notification?.body != null) {
      data['body'] = message.notification!.body!;
    }

    return NotificationPayload.fromMap(data);
  }

  /// Show local notification from remote message
  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = _createNotificationPayload(message);
    await showLocalNotification(
      title: notification.title ?? 'Raabta',
      body: notification.body ?? 'New message',
      payload: payload,
    );
  }

  @override
  Future<String?> getFCMToken() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    try {
      _currentToken ??= await _firebaseMessaging.getToken();
      return _currentToken;
    } catch (e) {
      if (kDebugMode) log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // Request FCM permissions
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      if (kDebugMode) {
        log('🔔 FCM Permission status: ${settings.authorizationStatus}');
      }

      // For Android 13+, also request notification permission
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
        final status = await Permission.notification.request();
        if (kDebugMode) {
          log('🔔 Android notification permission: $status');
        }
        return status.isGranted && settings.authorizationStatus == AuthorizationStatus.authorized;
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      if (kDebugMode) log('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) log('✅ Subscribed to topic: $topic');
    } catch (e) {
      if (kDebugMode) log('❌ Error subscribing to topic $topic: $e');
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      if (kDebugMode) log('❌ Error unsubscribing from topic $topic: $e');
      rethrow;
    }
  }

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationPayload? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: macOSDetails,
        linux: linuxDetails,
      );

      final String? payloadJson = payload != null ? jsonEncode(payload.toMap()) : null;

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        title,
        body,
        platformDetails,
        payload: payloadJson,
      );

      if (kDebugMode) log('✅ Local notification shown: $title');
    } catch (e) {
      if (kDebugMode) log('❌ Error showing local notification: $e');
    }
  }

  /// Get current notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Send call notification (for compatibility)
  Future<void> sendCallNotification(dynamic call) async {
    try {
      if (kDebugMode) log('📞 Sending call notification');
      
      // For now, we'll just show a local notification
      // In a real implementation, this would send FCM to other user
      await showLocalNotification(
        title: 'Incoming Call',
        body: 'You have an incoming call',
        payload: NotificationPayload(
          type: 'call',
          data: {'callId': call.id ?? call.callId ?? 'unknown'},
        ),
      );
      
      if (kDebugMode) log('✅ Call notification sent');
    } catch (e) {
      if (kDebugMode) log('❌ Failed to send call notification: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _onNotificationTapController.close();
    _onForegroundMessageController.close();
  }

  /// Update FCM token in Firestore for the current user
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final authService = ServiceLocator().authProviderOrNull;
      if (authService?.currentUser != null) {
        final userId = authService!.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        if (kDebugMode) log('✅ FCM token updated in Firestore');
      }
    } catch (e) {
      if (kDebugMode) log('❌ Failed to update FCM token in Firestore: $e');
    }
  }
}

/// Background message handler for Firebase messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    log('🔔 Background message received: ${message.messageId}');
    log('📱 Title: ${message.notification?.title}');
    log('📱 Body: ${message.notification?.body}');
    log('📱 Data: ${message.data}');
  }
  
  // Handle background message processing here if needed
  // Note: Don't call Flutter UI code here as the app might not be running
}