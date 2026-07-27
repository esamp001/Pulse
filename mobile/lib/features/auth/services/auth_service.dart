import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Static session state cache
  static String? _currentToken;
  static UserModel? _currentUser;

  // Base URL for backend API loaded from .env
  static String get baseUrl => dotenv.get('API_BASE_URL');

  /// Active session getters
  static String? get currentToken => _currentToken;
  static UserModel? get currentUser => _currentUser;

  /// Authenticate user via Google OAuth details
  Future<Map<String, dynamic>> googleAuthenticate({required String email, required String name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
      }),
    );

    if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
      throw Exception('Server returned HTML 404/500 instead of JSON. Status: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _processAuthResponse(responseData);
      return responseData;  
    } else {
      throw Exception(responseData['error'] ?? 'Google authentication failed');
    }
  }

  /// Register standard user
  Future<Map<String, dynamic>> register({required String name, required String email, String? password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201) {
      _processAuthResponse(responseData);
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'Registration failed');
    }
  }

  /// Login standard user
  Future<Map<String, dynamic>> login({required String email, String? password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _processAuthResponse(responseData);
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'Login failed');
    }
  }

  /// Fetch authenticated user profile from backend GET /me
  Future<UserModel> fetchCurrentUser() async {
    final token = _currentToken;
    if (token == null) {
      throw Exception('No active session token');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['data']?['user'] != null) {
      final user = UserModel.fromJson(responseData['data']['user']);
      _currentUser = user;
      return user;
    } else {
      throw Exception(responseData['error'] ?? 'Failed to fetch user session');
    }
  }

  /// Complete first-time user onboarding
  Future<UserModel> completeOnboarding({
    required String primarySport,
    required int rating,
    String? avatarUrl,
  }) async {
    final token = _currentToken;
    if (token == null) {
      throw Exception('No active session token');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/onboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'primary_sport': primarySport.toLowerCase(),
        'rating': rating,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['data']?['user'] != null) {
      final user = UserModel.fromJson(responseData['data']['user']);
      _currentUser = user;
      return user;
    } else {
      throw Exception(responseData['error'] ?? 'Failed to complete onboarding');
    }
  }

  /// Update or set user password
  Future<UserModel> updatePassword({ String? currentPassword, required String newPassword, }) async {
    final token = _currentToken;
    
    if (token == null) {
      throw Exception('No active session token');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (currentPassword != null && currentPassword.isNotEmpty)
          'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['data']?['user'] != null) {
      final user = UserModel.fromJson(responseData['data']['user']);
      _currentUser = user;
      return user;
    } else {
      throw Exception(responseData['error'] ?? 'Failed to update password');
    }
  }

  /// Upload user avatar image bytes via Cloudflare R2 presigned URL
  Future<String?> uploadAvatarImage(List<int> imageBytes, {String mimeType = 'image/jpeg'}) async {
    final token = _currentToken;
    if (token == null) {
      throw Exception('No active session token');
    }

    final rootUrl = baseUrl.replaceAll('/auth', '');
    final presignedResponse = await http.post(
      Uri.parse('$rootUrl/upload/presigned-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'contentType': mimeType}),
    );

    if (presignedResponse.statusCode != 200) {
      final err = jsonDecode(presignedResponse.body);
      throw Exception(err['error'] ?? 'Failed to request upload URL');
    }

    final data = jsonDecode(presignedResponse.body)['data'];
    final String uploadUrl = data['uploadUrl'];
    final String avatarUrl = data['avatarUrl'];

    // Upload directly to Cloudflare R2 via presigned URL
    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': mimeType},
      body: imageBytes,
    );

    if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 204 || uploadResponse.statusCode == 201) {
      return avatarUrl;
    } else {
      throw Exception('Failed to upload image file to storage');
    }
  }

  void _processAuthResponse(Map<String, dynamic> responseData) {
    final data = responseData['data'];

    if (data != null) {
      // Check if token is available
      if (data['token'] != null) {
        _currentToken = data['token']; // Assigned at the session state
      }

      // Check if user is available
      if (data['user'] != null) {
        _currentUser = UserModel.fromJson(data['user']); // Signed-in user
      }
    }
  }

  /// Clear active user session
  static void logout() {
    _currentToken = null;
    _currentUser = null;
  }
}
