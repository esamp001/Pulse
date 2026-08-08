import '../../../core/network/api_client.dart';
import '../models/match_model.dart';

class MatchService {
  final ApiClient _apiClient = ApiClient();

  /// Create a new match on backend
  Future<MatchModel> createMatch({
    required String sport,
    required String venueName,
    String? location,
    required DateTime scheduledAt,
    int totalSets = 3,
    int pointsToWinSet = 11,
    bool winByTwo = true,
  }) async {
    final data = await _apiClient.post('/matches', body: {
      'sport': sport,
      'venue_name': venueName,
      if (location != null && location.isNotEmpty) 'location': location,
      'scheduled_at': scheduledAt.toIso8601String(),
      'total_sets': totalSets,
      'points_to_win_set': pointsToWinSet,
      'win_by_two': winByTwo,
    });
    return MatchModel.fromJson(data);
  }

  /// Finalize match and declare winner (with True Elo rating change)
  Future<Map<String, dynamic>> finalizeMatch({
    required String matchId,
    required String winnerId,
    int player1SetsWon = 0,
    int player2SetsWon = 0,
    String? setScores,
  }) async {
    final data = await _apiClient.post('/matches/$matchId/complete', body: {
      'winner_id': winnerId,
      'player1_sets_won': player1SetsWon,
      'player2_sets_won': player2SetsWon,
      'set_scores': setScores,
    });

    return {
      'match': MatchModel.fromJson(data),
      'ratingChange': data['ratingChange'] ?? 25,
    };
  }

  /// Fetch user matches
  Future<List<MatchModel>> fetchUserMatches() async {
    final data = await _apiClient.get('/matches');
    if (data is List) {
      return data.map((item) => MatchModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get match details by ID
  Future<MatchModel> getMatchById(String matchId) async {
    final data = await _apiClient.get('/matches/$matchId');
    return MatchModel.fromJson(data);
  }

  /// Assign participant (player2 or scorer) to match
  Future<MatchModel> assignParticipant({
    required String matchId,
    required String role,
    required String targetUserId,
  }) async {
    final data = await _apiClient.patch('/matches/$matchId/participants', body: {
      'role': role,
      'user_id': targetUserId,
    });
    return MatchModel.fromJson(data);
  }

  /// Search registered users for invitation
  Future<List<MatchParticipantModel>> searchUsers(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final data = await _apiClient.get('/matches/users/search?q=$encodedQuery');
    if (data is List) {
      return data.map((item) => MatchParticipantModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get current user's active match (if any)
  Future<MatchModel?> getActiveMatch() async {
    try {
      final data = await _apiClient.get('/matches/active');
      if (data != null && data is Map<String, dynamic>) {
        return MatchModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exit or cancel match room
  Future<void> exitMatch(String matchId) async {
    await _apiClient.delete('/matches/$matchId/exit');
  }

  /// Accept match invitation
  Future<MatchModel> acceptInvitation(String matchId) async {
    final data = await _apiClient.patch('/matches/$matchId/accept');
    return MatchModel.fromJson(data);
  }

  /// Decline match invitation
  Future<MatchModel> declineInvitation(String matchId) async {
    final data = await _apiClient.patch('/matches/$matchId/decline');
    return MatchModel.fromJson(data);
  }

  /// Kick participant (player2 or scorer) from match room
  Future<MatchModel> kickParticipant({
    required String matchId,
    required String role,
  }) async {
    final data = await _apiClient.delete('/matches/$matchId/participants/$role');
    return MatchModel.fromJson(data);
  }

  /// Update match status (e.g. READY -> LIVE, LIVE -> FINISHED)
  Future<MatchModel> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    final data = await _apiClient.patch('/matches/$matchId/status', body: {
      'status': status,
    });
    return MatchModel.fromJson(data);
  }

  /// Join an active match using a 6-digit court PIN code
  Future<MatchModel> joinMatchByPin(String pinCode) async {
    final data = await _apiClient.post('/matches/join-by-pin', body: {
      'pin': pinCode.trim(),
    });
    return MatchModel.fromJson(data);
  }

  /// Switch participant role slot inside match lobby room
  Future<MatchModel> switchParticipantRole({
    required String matchId,
    required String targetRole,
  }) async {
    final data = await _apiClient.patch('/matches/$matchId/switch-role', body: {
      'target_role': targetRole,
    });
    return MatchModel.fromJson(data);
  }
}
