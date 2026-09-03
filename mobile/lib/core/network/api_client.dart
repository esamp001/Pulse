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
    const String envDefinedUrl = String.fromEnvironment('API_BASE_URL');
    if (envDefinedUrl.isNotEmpty) {
      if (envDefinedUrl.endsWith('/auth')) {
        return envDefinedUrl.replaceAll('/auth', '');
      }
      return envDefinedUrl;
    }

    try {
      if (dotenv.isInitialized) {
        final rawUrl = dotenv.get(
          'API_BASE_URL',
          fallback: 'http://localhost:5000/api/v1',
        );
        if (rawUrl.endsWith('/auth')) {
          return rawUrl.replaceAll('/auth', '');
        }
        return rawUrl;
      }
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }

  /// Construct HTTP headers with dynamic JWT Bearer token injection
  Map<String, String> _buildHeaders({Map<String, String>? customHeaders}) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = AuthService.currentToken;

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Resolve URI safely, supporting both relative API endpoints and absolute external URLs (e.g. R2/S3 presigned URLs)
  Uri _resolveUri(String endpoint, {Map<String, String>? queryParams}) {
    final isExternal =
        endpoint.startsWith('http://') || endpoint.startsWith('https://');

    if (isExternal) {
      final parsed = Uri.parse(endpoint);
      return queryParams != null
          ? parsed.replace(queryParameters: queryParams)
          : parsed;
    }

    final cleanPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse(
      '$baseUrl$cleanPath',
    ).replace(queryParameters: queryParams);
  }

  /// Build request headers based on whether the target endpoint is an internal API or external storage URL
  Map<String, String> _buildHeadersForEndpoint(
    String endpoint, {
    Map<String, String>? customHeaders,
  }) {
    final isExternal =
        endpoint.startsWith('http://') || endpoint.startsWith('https://');

    if (isExternal) {
      // Do not inject backend JWT Bearer tokens into external pre-signed S3/Cloudflare R2 URLs
      return customHeaders ?? <String, String>{};
    }
    return _buildHeaders(customHeaders: customHeaders);
  }

  /// Encode body data cleanly without jsonEncoding raw binary bytes (`List<int>`) or external requests
  Object? _encodeBody(Object? body, bool isExternal) {
    if (body == null) {
      return null;
    }

    if (body is List<int> || body is String || isExternal) return body;
    return jsonEncode(body);
  }

  /// Process HTTP response and return parsed JSON data payload
  dynamic _processResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';

    // Check if the server returned HTML (e.g. 404, 502 Bad Gateway)
    if (contentType.contains('text/html') ||
        response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      throw Exception(
        'Server returned an unexpected HTML response instead of JSON. The service may be offline or misconfigured.',
      );
    }

    dynamic responseData;
    if (response.body.isNotEmpty) {
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to decode server response as JSON: $e');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    final errorMessage = responseData is Map && responseData['error'] != null
        ? responseData['error']
        : 'Request failed with status code ${response.statusCode}';
    throw Exception(errorMessage);
  }

  bool get _shouldLog => kDebugMode && dotenv.isInitialized;

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _resolveUri(endpoint, queryParams: queryParams);
      final reqHeaders = _buildHeadersForEndpoint(
        endpoint,
        customHeaders: headers,
      );
      final response = await http.get(uri, headers: reqHeaders);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        debugPrint('[ApiClient GET Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final isExternal =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final uri = _resolveUri(endpoint);
      final reqHeaders = _buildHeadersForEndpoint(
        endpoint,
        customHeaders: headers,
      );
      final reqBody = _encodeBody(body, isExternal);
      final response = await http.post(uri, headers: reqHeaders, body: reqBody);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        debugPrint('[ApiClient POST Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final isExternal =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final uri = _resolveUri(endpoint);
      final reqHeaders = _buildHeadersForEndpoint(
        endpoint,
        customHeaders: headers,
      );
      final reqBody = _encodeBody(body, isExternal);
      final response = await http.patch(
        uri,
        headers: reqHeaders,
        body: reqBody,
      );
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        debugPrint('[ApiClient PATCH Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final isExternal =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final uri = _resolveUri(endpoint);
      final reqHeaders = _buildHeadersForEndpoint(
        endpoint,
        customHeaders: headers,
      );
      final reqBody = _encodeBody(body, isExternal);
      final response = await http.put(uri, headers: reqHeaders, body: reqBody);
      return _processResponse(response);
    } catch (err) {
      if (_shouldLog) {
        debugPrint('[ApiClient PUT Error] $endpoint: $err');
      }
      rethrow;
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final isExternal =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final uri = _resolveUri(endpoint);
      final reqHeaders = _buildHeadersForEndpoint(
        endpoint,
        customHeaders: headers,
      );
      final reqBody = _encodeBody(body, isExternal);
      final response = await http.delete(
        uri,
        headers: reqHeaders,
        body: reqBody,
      );
      return _processResponse(response);
    } catch (err) {
      if (kDebugMode) {
        debugPrint('[ApiClient DELETE Error] $endpoint: $err');
      }
      rethrow;
    }
  }
}
