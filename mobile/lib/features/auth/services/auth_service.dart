import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Base URL for backend API loaded from .env
  static String get baseUrl => dotenv.get('API_BASE_URL');

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
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'Registration failed');
    }
  }
}
