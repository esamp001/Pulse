import '../../../core/network/api_client.dart';

/// Community Service for persistent waitlist subscriptions in PostgreSQL
class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Subscribe user to feature waitlist
  Future<bool> subscribeWaitlist({String? email, String feature = 'community'}) async {
    try {
      await _apiClient.post('/community/waitlist/subscribe', body: {
        if (email != null && email.isNotEmpty) 'email': email,
        'feature': feature,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Unsubscribe user from feature waitlist
  Future<bool> unsubscribeWaitlist({String? email, String feature = 'community'}) async {
    try {
      await _apiClient.post('/community/waitlist/unsubscribe', body: {
        if (email != null && email.isNotEmpty) 'email': email,
        'feature': feature,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get current waitlist subscription status
  Future<bool> fetchWaitlistStatus({String? email, String feature = 'community'}) async {
    try {
      final queryParams = <String, String>{'feature': feature};
      if (email != null && email.isNotEmpty) {
        queryParams['email'] = email;
      }
      final data = await _apiClient.get('/community/waitlist/status', queryParams: queryParams);
      if (data is Map<String, dynamic>) {
        return data['isSubscribed'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
