import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../models/court_model.dart';
import '../models/court_review_model.dart';

class CourtService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch nearby courts with sport filter, search term, and geographic radius
  Future<List<CourtModel>> fetchNearbyCourts({
    double lat = 14.5995,
    double lng = 120.9842,
    double radiusKm = 25,
    String? sport,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
      };

      if (sport != null && sport.isNotEmpty && sport.toLowerCase() != 'all') {
        queryParams['sport'] = sport.toLowerCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _apiClient.get(
        '/courts',
        queryParams: queryParams,
      );

      List<dynamic> listData = [];
      if (response is Map<String, dynamic> && response['data'] is List) {
        listData = response['data'] as List<dynamic>;
      } else if (response is List) {
        listData = response;
      }

      if (listData.isNotEmpty) {
        return listData
            .map((e) => CourtModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('[CourtService fetchNearbyCourts Error]: $e');
      return [];
    }
  }

  /// Force on-demand sync from OpenStreetMap Overpass API
  Future<int> syncOsm({
    double lat = 14.5995,
    double lng = 120.9842,
    double radiusKm = 15,
    String? sport,
  }) async {
    try {
      final response = await _apiClient.post(
        '/courts/sync',
        body: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          if (sport != null && sport.isNotEmpty) 'sport': sport.toLowerCase(),
        },
      );

      if (response is Map<String, dynamic> && response['syncedCount'] != null) {
        return (response['syncedCount'] as num).toInt();
      }
      return 0;
    } catch (e) {
      debugPrint('[CourtService syncOsm Error]: $e');
      return 0;
    }
  }

  /// Search locations/addresses worldwide using OpenStreetMap Nominatim
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&addressdetails=1&limit=6&countrycodes=ph',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'RallyPulseApp/1.0 (support@rallypulse.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          return _parseNominatimResults(data);
        }
      }

      // Fallback without countrycodes if local results are empty
      final globalUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&addressdetails=1&limit=6',
      );
      final globalRes = await http
          .get(
            globalUri,
            headers: {
              'User-Agent': 'RallyPulseApp/1.0 (support@rallypulse.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (globalRes.statusCode == 200) {
        final globalData = jsonDecode(globalRes.body);
        if (globalData is List) {
          return _parseNominatimResults(globalData);
        }
      }

      return [];
    } catch (e) {
      debugPrint('[CourtService searchLocations Error]: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _parseNominatimResults(List data) {
    return data
        .map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final displayName = item['display_name']?.toString() ?? '';
          final address = item['address'] as Map<String, dynamic>?;
          final road =
              address?['road'] ??
              address?['pedestrian'] ??
              address?['suburb'] ??
              '';
          final city =
              address?['city'] ??
              address?['town'] ??
              address?['municipality'] ??
              address?['state'] ??
              '';
          final label = road.isNotEmpty && city.isNotEmpty
              ? '$road, $city'
              : displayName;

          return {
            'lat': lat,
            'lon': lon,
            'label': label,
            'displayName': displayName,
            'city': city,
            'road': road,
          };
        })
        .where((e) => (e['lat'] as double) != 0.0)
        .toList();
  }

  /// Reverse geocode coordinates to get street address and city
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'RallyPulseApp/1.0 (support@rallypulse.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final address = data['address'] as Map<String, dynamic>?;
          final road =
              address?['road'] ??
              address?['pedestrian'] ??
              address?['suburb'] ??
              address?['neighbourhood'] ??
              '';
          final city =
              address?['city'] ??
              address?['town'] ??
              address?['municipality'] ??
              address?['state'] ??
              '';
          final fullAddress = data['display_name']?.toString() ?? '';
          final venueName = data['name']?.toString() ?? '';

          return {
            'address': road.isNotEmpty ? road.toString() : fullAddress,
            'city': city.toString(),
            'name': venueName,
            'fullAddress': fullAddress,
          };
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Upload court photo image bytes via backend presigned upload endpoint
  Future<String?> uploadCourtPhoto(
    List<int> imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final presignedData = await _apiClient.post(
        '/upload/presigned-url',
        body: {'contentType': mimeType},
      );

      final String uploadUrl = presignedData['uploadUrl'];
      final String photoUrl = presignedData['avatarUrl'];

      await _apiClient.put(
        uploadUrl,
        body: imageBytes,
        headers: {'Content-Type': mimeType},
      );
      return photoUrl;
    } catch (err) {
      debugPrint('[CourtService uploadCourtPhoto Error]: $err');
      return null;
    }
  }

  /// Submit a player-suggested court to the backend
  Future<CourtModel?> suggestCourt({
    required String name,
    String? address,
    String? city,
    required double latitude,
    required double longitude,
    required List<String> sports,
    String? surface,
    bool hasLighting = false,
    bool isIndoor = false,
    String accessType = 'public',
    String? imageUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/courts',
        body: {
          'name': name,
          'address': address,
          'city': city,
          'latitude': latitude,
          'longitude': longitude,
          'sports': sports,
          'surface': surface,
          'has_lighting': hasLighting,
          'is_indoor': isIndoor,
          'access_type': accessType,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        },
      );

      // ApiClient unwraps the backend response envelope and returns its `data`
      // value directly, so the court fields are at the response root here.
      if (response is Map<String, dynamic>) {
        return CourtModel.fromJson(response);
      }
      return null;
    } catch (err) {
      return null;
    }
  }

  /// Fetch court reviews and rating statistics
  Future<Map<String, dynamic>> fetchCourtReviews(String courtId) async {
    try {
      final response = await _apiClient.get('/courts/$courtId/reviews');
      final data =
          (response is Map<String, dynamic> &&
              response['data'] is Map<String, dynamic>)
          ? (response['data'] as Map<String, dynamic>)
          : (response is Map<String, dynamic> ? response : null);

      if (data != null) {
        final reviewsList =
            (data['reviews'] as List<dynamic>?)
                ?.map(
                  (e) => CourtReviewModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [];

        return {
          'likesCount': data['likesCount'] ?? 0,
          'dislikesCount': data['dislikesCount'] ?? 0,
          'totalVotes': data['totalVotes'] ?? 0,
          'recommendationPercent': data['recommendationPercent'] ?? 0,
          'userVote': data['userVote'],
          'reviews': reviewsList,
        };
      }
      return {
        'likesCount': 0,
        'dislikesCount': 0,
        'totalVotes': 0,
        'recommendationPercent': 0,
        'reviews': <CourtReviewModel>[],
      };
    } catch (e) {
      debugPrint('[CourtService fetchCourtReviews Error]: $e');
      return {
        'likesCount': 0,
        'dislikesCount': 0,
        'totalVotes': 0,
        'recommendationPercent': 0,
        'reviews': <CourtReviewModel>[],
      };
    }
  }

  /// Submit or update a court review (Like/Dislike with optional comment)
  Future<Map<String, dynamic>?> submitCourtReview({
    required String courtId,
    required bool isLiked,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.post(
        '/courts/$courtId/reviews',
        body: {'is_liked': isLiked, 'comment': comment},
      );

      final data =
          (response is Map<String, dynamic> &&
              response['data'] is Map<String, dynamic>)
          ? (response['data'] as Map<String, dynamic>)
          : (response is Map<String, dynamic> ? response : null);

      if (data != null) {
        CourtReviewModel? review;
        if (data['id'] != null) {
          review = CourtReviewModel.fromJson(data);
        }
        return {
          'review': review,
          'likesCount': data['likesCount'] as int?,
          'dislikesCount': data['dislikesCount'] as int?,
          'totalVotes': data['totalVotes'] as int?,
          'recommendationPercent': data['recommendationPercent'] as int?,
          'userVote': data['userVote'] as bool?,
        };
      }
      return null;
    } catch (e) {
      debugPrint('[CourtService submitCourtReview Error]: $e');
      return null;
    }
  }

  /// Delete a user's court review
  Future<bool> deleteCourtReview(String courtId) async {
    try {
      final response = await _apiClient.delete('/courts/$courtId/reviews');
      return response != null;
    } catch (e) {
      debugPrint('[CourtService deleteCourtReview Error]: $e');
      return false;
    }
  }
}
