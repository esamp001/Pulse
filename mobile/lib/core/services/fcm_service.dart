import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../../features/auth/services/auth_service.dart';

/// Centralized Mobile Push Notification Manager (FCM)
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  String? _lastToken;

  /// Register current device's FCM Push Token with backend API
  Future<void> registerFcmToken(String fcmToken) async {
    if (_lastToken == fcmToken) return;
    try {
      if (AuthService.currentToken == null) return;
      
      await ApiClient().patch('/auth/fcm-token', body: {
        'fcmToken': fcmToken,
      });

      _lastToken = fcmToken;
      if (kDebugMode) {
        print('[FcmService] FCM token registered with backend cleanly');
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmService Error]: Failed to register FCM token: $err');
      }
    }
  }

  /// Remove FCM Token on logout
  Future<void> unregisterFcmToken() async {
    try {
      if (AuthService.currentToken != null) {
        await ApiClient().patch('/auth/fcm-token', body: {
          'fcmToken': null,
        });
      }
    } catch (_) {}
    _lastToken = null;
  }
}
