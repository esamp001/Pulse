import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardService {
  static String get _leaderboardUrl {
    final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/api/v1/auth');
    if (baseUrl.endsWith('/auth')) {
      return baseUrl.replaceAll('/auth', '/leaderboard');
    }
    return '$baseUrl/leaderboard';
  }

  Future<LeaderboardResponseModel> fetchLeaderboard({
    String sport = 'all',
    String category = 'elo',
    int limit = 50,
    int offset = 0,
  }) async {
    final token = AuthService.currentToken;
    final uri = Uri.parse(_leaderboardUrl).replace(queryParameters: {
      'sport': sport,
      'category': category,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
      throw Exception('Server error (HTML response). Status code: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return LeaderboardResponseModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to fetch leaderboard data');
    }
  }
}
