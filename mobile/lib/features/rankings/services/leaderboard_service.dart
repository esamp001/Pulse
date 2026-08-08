import '../../../core/network/api_client.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardService {
  final ApiClient _apiClient = ApiClient();

  Future<LeaderboardResponseModel> fetchLeaderboard({
    String sport = 'all',
    String category = 'elo',
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _apiClient.get('/leaderboard', queryParams: {
      'sport': sport,
      'category': category,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    return LeaderboardResponseModel.fromJson(data);
  }
}
