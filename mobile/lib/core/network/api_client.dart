import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/services/auth_service.dart';

/// Centralized API Client for Pulse Flutter Mobile Frontend
/// Handles base URL resolution, dynamic JWT auth header injection,
/// HTML error checks, status code evaluation, and JSON payload decoding.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Resolve root API base URL safely with test mode & legacy dotenv fallbacks
  String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        final rawUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/api/v1');
        if (rawUrl.endsWith('/auth')) {
          return rawUrl.replaceAll('/auth', '');
        }
        return rawUrl;
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  /// Construct HTTP headers with dynamic JWT Bearer token injection
  Map<String, String> _buildHeaders({Map<String, String>? customHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = AuthService.currentToken;

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Process HTTP response and return parsed JSON data payload
  dynamic _processResponse(http.Response response) {
    final bodyStr = response.body.trim();

    if (bodyStr.startsWith('<!DOCTYPE') || bodyStr.startsWith('<html')) {
      throw Exception('Server error (HTML response). Status code: ${response.statusCode}');
    }

    dynamic responseData;
    if (bodyStr.isNotEmpty) {
      try {
        responseData = jsonDecode(bodyStr);
      } catch (e) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return bodyStr;
        }
        throw Exception('Invalid JSON response from server');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        return responseData['data'];
      }
      return responseData;
    }

    final errorMessage = (responseData is Map<String, dynamic> && responseData.containsKey('error'))
        ? responseData['error']
        : 'Request failed with status code ${response.statusCode}';

    throw Exception(errorMessage);
  }

  bool get _shouldLog => kDebugMode && dotenv.isInitialized;

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, Map<String, String>? headers}) async {
    try {
      final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanPath').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _buildHeaders(customHeaders: headers));
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        print('[ApiClient GET Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// POST request
  Future<dynamic> post(String endpoint, {Object? body, Map<String, String>? headers}) async {
    try {
      final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanPath');
      final encodedBody = body is String ? body : jsonEncode(body);
      final response = await http.post(uri, headers: _buildHeaders(customHeaders: headers), body: encodedBody);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        print('[ApiClient POST Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// PATCH request
  Future<dynamic> patch(String endpoint, {Object? body, Map<String, String>? headers}) async {
    try {
      final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanPath');
      final encodedBody = body is String ? body : jsonEncode(body);
      final response = await http.patch(uri, headers: _buildHeaders(customHeaders: headers), body: encodedBody);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        print('[ApiClient PATCH Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {Object? body, Map<String, String>? headers}) async {
    try {
      final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanPath');
      final encodedBody = body is String ? body : jsonEncode(body);
      final response = await http.put(uri, headers: _buildHeaders(customHeaders: headers), body: encodedBody);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        print('[ApiClient PUT Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint, {Object? body, Map<String, String>? headers}) async {
    try {
      final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanPath');
      final encodedBody = body != null ? (body is String ? body : jsonEncode(body)) : null;
      final response = await http.delete(uri, headers: _buildHeaders(customHeaders: headers), body: encodedBody);
      return _processResponse(response);
    } catch (err) {
      if (kDebugMode) {
        print('[ApiClient DELETE Error] $endpoint: $err');
      }
      rethrow;
    }
  }
}
