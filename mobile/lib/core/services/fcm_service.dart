import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
  static bool _isInitialized = false;

  /// Initialize Firebase Messaging listeners, permissions, and initial token sync
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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
        });

        // 5. App Opened From Notification Event
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('[FCM Notification Opened App]: ${message.data}');
          }
        });
      }

      _isInitialized = true;
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Initialization Error]: $err');
      }
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
