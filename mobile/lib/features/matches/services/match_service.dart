import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';
import '../models/match_model.dart';

class MatchService {
  /// Base API URL for matches endpoints
  static String get _matchesUrl {
    final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/api/v1/auth');
    // Replace '/auth' with '/matches' if present, or format correctly
    if (baseUrl.endsWith('/auth')) {
      return baseUrl.replaceAll('/auth', '/matches');
    }
    return '$baseUrl/matches';
  }

  /// Create a new match on backend
  Future<MatchModel> createMatch({
    required String sport,
    required String venueName,
    String? location,
    required DateTime scheduledAt,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.post(
      Uri.parse(_matchesUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sport': sport,
        'venue_name': venueName,
        if (location != null && location.isNotEmpty) 'location': location,
        'scheduled_at': scheduledAt.toIso8601String(),
      }),
    );

    if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
      throw Exception('Server error (HTML response). Status code: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to create match');
    }
  }

  /// Fetch user matches
  Future<List<MatchModel>> fetchUserMatches() async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.get(
      Uri.parse(_matchesUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> list = responseData['data'] ?? [];
      return list.map((item) => MatchModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['error'] ?? 'Failed to fetch matches');
    }
  }

  /// Get match details by ID
  Future<MatchModel> getMatchById(String matchId) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$_matchesUrl/$matchId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to fetch match details');
    }
  }

  /// Assign participant (player2 or scorer) to match
  Future<MatchModel> assignParticipant({
    required String matchId,
    required String role,
    required String targetUserId,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.patch(
      Uri.parse('$_matchesUrl/$matchId/participants'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'role': role,
        'user_id': targetUserId,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to assign participant');
    }
  }

  /// Search registered users for invitation
  Future<List<MatchParticipantModel>> searchUsers(String query) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(
      Uri.parse('$_matchesUrl/users/search?q=$encodedQuery'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> list = responseData['data'] ?? [];
      return list.map((item) => MatchParticipantModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['error'] ?? 'Failed to search users');
    }
  }

  /// Get current user's active match (if any)
  Future<MatchModel?> getActiveMatch() async {
    final token = AuthService.currentToken;
    if (token == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_matchesUrl/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          return MatchModel.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exit or cancel match room
  Future<void> exitMatch(String matchId) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.delete(
      Uri.parse('$_matchesUrl/$matchId/exit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['error'] ?? 'Failed to exit match room');
    }
  }

  /// Accept match invitation
  Future<MatchModel> acceptInvitation(String matchId) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.patch(
      Uri.parse('$_matchesUrl/$matchId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to accept invitation');
    }
  }

  /// Decline match invitation
  Future<MatchModel> declineInvitation(String matchId) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.patch(
      Uri.parse('$_matchesUrl/$matchId/decline'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to decline invitation');
    }
  }

  /// Kick participant (player2 or scorer) from match room
  Future<MatchModel> kickParticipant({
    required String matchId,
    required String role,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.delete(
      Uri.parse('$_matchesUrl/$matchId/participants/$role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to kick participant');
    }
  }

  /// Update match status (e.g. READY -> LIVE, LIVE -> FINISHED)
  Future<MatchModel> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    final response = await http.patch(
      Uri.parse('$_matchesUrl/$matchId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return MatchModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['error'] ?? 'Failed to update match status');
    }
  }
}

