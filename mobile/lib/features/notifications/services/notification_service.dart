import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/notification_item_model.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/matches/models/match_model.dart';
import '../../../../core/network/api_client.dart';

/// Notification Service for handling backend PostgreSQL & dynamic notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();

  static const String _prefReadIdsKey = 'pulse_read_notification_ids';
  final List<NotificationItemModel> _notifications = [];
  final Set<String> _readIds = {};
  bool _hasLoadedPrefs = false;

  Future<void> _loadReadIdsFromStorage() async {
    if (_hasLoadedPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList(_prefReadIdsKey) ?? [];
      _readIds.addAll(savedIds);
      _hasLoadedPrefs = true;
    } catch (_) {}
  }

  Future<void> _saveReadIdsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefReadIdsKey, _readIds.toList());
    } catch (_) {}
  }



  List<NotificationItemModel> getNotifications({bool unreadOnly = false}) {
    if (unreadOnly) {
      return _notifications.where((n) => n.isUnread).toList();
    }
    return List.unmodifiable(_notifications);
  }

  /// Fetch notifications directly from PostgreSQL backend by user_id
  Future<List<NotificationItemModel>> fetchBackendNotifications({
    required UserModel? user,
    required List<MatchModel> historyMatches,
  }) async {
    await _loadReadIdsFromStorage();
    final token = AuthService.currentToken;
    if (token != null) {
      try {
        final data = await _apiClient.get('/notifications');
        if (data is List && data.isNotEmpty) {
          _notifications.clear();
          for (final jsonItem in data) {
            final model = NotificationItemModel.fromJson(jsonItem);
            if (_readIds.contains(model.id)) {
              model.isUnread = false;
            } else if (!model.isUnread) {
              _readIds.add(model.id);
            }
            _notifications.add(model);
          }
          await _saveReadIdsToStorage();
          return List.unmodifiable(_notifications);
        }
      } catch (e) {
        // Fallback to local dynamic generator if offline or server connecting
      }
    }

    populateDynamicNotifications(user: user, historyMatches: historyMatches);
    return List.unmodifiable(_notifications);
  }

  /// Mark notification as read both locally and in PostgreSQL database
  Future<void> markAsRead(String id) async {
    _readIds.add(id);
    await _saveReadIdsToStorage();

    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isUnread = false;
    }

    final token = AuthService.currentToken;
    if (token != null && !id.startsWith('account_') && !id.startsWith('welcome_') && !id.startsWith('rating_') && !id.startsWith('match_')) {
      try {
        await _apiClient.patch('/notifications/$id/read');
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final item in _notifications) {
      _readIds.add(item.id);
      item.isUnread = false;
    }
    await _saveReadIdsToStorage();

    final token = AuthService.currentToken;
    if (token != null) {
      try {
        await _apiClient.patch('/notifications/read-all');
      } catch (_) {}
    }
  }

  /// Fallback dynamic populator
  void populateDynamicNotifications({
    required UserModel? user,
    required List<MatchModel> historyMatches,
  }) {
    _notifications.clear();

    // 1. Account & Security Notifications
    if (user != null) {
      if (user.authProvider != 'email') {
        const id = 'account_auth_provider';
        _notifications.add(
          NotificationItemModel(
            id: id,
            category: NotificationCategory.account,
            title: 'Signed in via ${user.authProvider.toUpperCase()}',
            subtitle: 'You are securely logged in as ${user.email}. Password setup is optional.',
            dateText: 'Active',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isUnread: !_readIds.contains(id),
          ),
        );
      } else if (!user.hasPassword) {
        const id = 'account_security_pass';
        _notifications.add(
          NotificationItemModel(
            id: id,
            category: NotificationCategory.account,
            title: 'Action Recommended: Set Password',
            subtitle: 'Create a Rally password for your email account in Profile Settings.',
            dateText: 'Security',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            isUnread: !_readIds.contains(id),
          ),
        );
      }

      // Onboarding Welcome Notification
      const welcomeId = 'welcome_onboarding';
      _notifications.add(
        NotificationItemModel(
          id: welcomeId,
          category: NotificationCategory.account,
          title: 'Welcome to Rally!',
          subtitle: 'Welcome ${user.firstName.isNotEmpty ? user.firstName : "Athlete"}! Your profile is active. Create or join a match anytime.',
          dateText: 'Welcome',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isUnread: !_readIds.contains(welcomeId),
        ),
      );

      // Rating Update Notification
      const ratingId = 'rating_current';
      _notifications.add(
        NotificationItemModel(
          id: ratingId,
          category: NotificationCategory.rating,
          title: '${user.formattedSport} ELO Status',
          subtitle: 'Current Official Rating: ${user.formattedRating} (${user.recordText})',
          dateText: '2 minutes ago',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          isUnread: !_readIds.contains(ratingId),
        ),
      );
    }

    // 2. Dynamic Notifications from Match History
    final currentUserId = user?.id;
    for (int i = 0; i < historyMatches.length; i++) {
      final match = historyMatches[i];
      final isP1 = match.player1Id == currentUserId;
      final opponent = isP1 ? match.player2 : match.player1;
      final opponentName = (opponent != null && opponent.name.isNotEmpty && opponent.name != 'Anonymous')
          ? opponent.name
          : 'Match Opponent';
      final dateStr = match.createdAt != null
          ? '${match.createdAt!.month}/${match.createdAt!.day}/${match.createdAt!.year}'
          : 'Recent';
      final isWin = match.winnerId != null && match.winnerId == currentUserId;
      final outcome = isWin ? 'Victory' : 'Result Verified';
      final matchNotificationId = 'match_${match.id}';

      _notifications.add(
        NotificationItemModel(
          id: matchNotificationId,
          category: NotificationCategory.verified,
          title: 'Match $outcome vs $opponentName',
          subtitle: '${match.sportDisplayName} at ${match.venueName} • Status: ${match.status}',
          dateText: dateStr,
          timestamp: match.createdAt ?? DateTime.now(),
          isUnread: !_readIds.contains(matchNotificationId),
          payload: {'matchId': match.id},
        ),
      );
    }

    // Sort by newest timestamp
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
