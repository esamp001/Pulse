import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Top-level entry point background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print('[FCM Background Message Received]: ${message.messageId} | Title: ${message.notification?.title}');
    }
  } catch (err) {
    if (kDebugMode) {
      print('[FCM Background Handler Error]: $err');
    }
  }
}

/// Centralized FCM Push Notification Handler for Rally Mobile App
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'rally_notifications',
    'Rally notifications',
    description: 'Match and account notifications from Rally.',
    importance: Importance.high,
  );
  static bool _isInitialized = false;
  static Future<void> Function(Map<String, dynamic> data)? _onNotificationTap;

  static void configure({
    required Future<void> Function(Map<String, dynamic> data) onNotificationTap,
  }) {
    _onNotificationTap = onNotificationTap;
  }

  /// Initialize Firebase Messaging listeners, permissions, and initial token sync
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();

      // 1. Request Notification Permissions from User (iOS & Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('[FCM Permission Status]: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Set foreground notification options for iOS
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 2. Fetch current device token & sync to backend
        await syncCurrentToken();

        // 3. Listen for token refresh events
        _messaging.onTokenRefresh.listen((newToken) {
          syncTokenToBackend(newToken);
        });

        // 4. Foreground Message Listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('[FCM Foreground Message Received]: ${message.notification?.title} - ${message.notification?.body}');
          }
          unawaited(_showForegroundNotification(message));
        });

        // 5. App Opened From Notification Event
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('[FCM Notification Opened App]: ${message.data}');
          }
          unawaited(_handleNotificationTap(message.data));
        });

        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          await _handleNotificationTap(initialMessage.data);
        }
      }

      _isInitialized = true;
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Initialization Error]: $err');
      }
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            unawaited(_handleNotificationTap(data));
          }
        } catch (err) {
          if (kDebugMode) {
            print('[FCM Local Notification Payload Error]: $err');
          }
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rally_notifications',
          'Rally notifications',
          channelDescription: 'Match and account notifications from Rally.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final onNotificationTap = _onNotificationTap;
    if (onNotificationTap != null) {
      await onNotificationTap(data);
    }
  }

  /// Explicitly fetch current device FCM token and sync to backend
  static Future<void> syncCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await syncTokenToBackend(token);
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Sync Current Token Error]: $err');
      }
    }
  }

  /// Sync active FCM Token to Node.js backend (`PATCH /auth/fcm-token`)
  static Future<void> syncTokenToBackend(String token) async {
    try {
      await ApiClient().patch(
        '/auth/fcm-token',
        body: {'fcmToken': token},
      );
      if (kDebugMode) {
        print('[FcmService]: Device FCM token successfully synced to backend.');
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Sync Token Error]: $err');
      }
    }
  }

  /// Clear FCM Token from backend on user logout
  static Future<void> clearTokenOnBackend() async {
    try {
      await ApiClient().patch(
        '/auth/fcm-token',
        body: {'fcmToken': null},
      );
      if (kDebugMode) {
        print('[FcmService]: FCM token cleared on backend.');
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Clear Token Error]: $err');
      }
    }
  }
}
