class CourtModel {
  final String id;
  final String? osmId;
  final String name;
  final String? address;
  final String? city;
  final double latitude;
  final double longitude;
  final List<String> sports;
  final String? surface;
  final bool hasLighting;
  final bool isIndoor;
  final String accessType;
  final bool isVerified;
  final double? distanceKm;
  final String? imageUrl;
  final int likesCount;
  final int dislikesCount;
  final bool? userVote; // true = liked, false = disliked, null = not voted

  const CourtModel({
    required this.id,
    this.osmId,
    required this.name,
    this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.sports,
    this.surface,
    this.hasLighting = false,
    this.isIndoor = false,
    this.accessType = 'public',
    this.isVerified = true,
    this.distanceKm,
    this.imageUrl,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userVote,
  });

  String get primarySport {
    if (sports.isEmpty) return 'Pickleball';
    final s = sports.first.toLowerCase();
    if (s.contains('pickleball')) return 'Pickleball';
    if (s.contains('tennis')) return 'Tennis';
    if (s.contains('badminton')) return 'Badminton';
    if (s.contains('table')) return 'Table Tennis';
    return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : 'Pickleball';
  }

  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  int get totalVotes => likesCount + dislikesCount;

  int get recommendationPercent =>
      totalVotes > 0 ? ((likesCount / totalVotes) * 100).round() : 0;

  bool get isRecommended => recommendationPercent >= 70 && totalVotes >= 3;

  CourtModel copyWith({
    String? id,
    String? osmId,
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    List<String>? sports,
    String? surface,
    bool? hasLighting,
    bool? isIndoor,
    String? accessType,
    bool? isVerified,
    double? distanceKm,
    String? imageUrl,
    int? likesCount,
    int? dislikesCount,
    bool? userVote,
  }) {
    return CourtModel(
      id: id ?? this.id,
      osmId: osmId ?? this.osmId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sports: sports ?? this.sports,
      surface: surface ?? this.surface,
      hasLighting: hasLighting ?? this.hasLighting,
      isIndoor: isIndoor ?? this.isIndoor,
      accessType: accessType ?? this.accessType,
      isVerified: isVerified ?? this.isVerified,
      distanceKm: distanceKm ?? this.distanceKm,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      userVote: userVote ?? this.userVote,
    );
  }

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSports = [];
    if (json['sports'] is List) {
      parsedSports = (json['sports'] as List).map((e) => e.toString()).toList();
    } else if (json['sports'] is String) {
      parsedSports = [json['sports'].toString()];
    }

    double parseDouble(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    bool? parseBool(dynamic val) {
      if (val == null) return null;
      if (val is bool) return val;
      if (val == 1 || val == '1' || val == 'true') return true;
      if (val == 0 || val == '0' || val == 'false') return false;
      return null;
    }

    return CourtModel(
      id: json['id']?.toString() ?? '',
      osmId: json['osm_id']?.toString(),
      name: json['name']?.toString() ?? 'Sports Court',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      latitude: parseDouble(json['latitude'], 14.5995),
      longitude: parseDouble(json['longitude'], 120.9842),
      sports: parsedSports.isNotEmpty ? parsedSports : ['pickleball'],
      surface: json['surface']?.toString(),
      hasLighting: json['has_lighting'] == true,
      isIndoor: json['is_indoor'] == true,
      accessType: json['access_type']?.toString() ?? 'public',
      isVerified: json['is_verified'] != false,
      distanceKm: json['distance_km'] != null ? parseDouble(json['distance_km'], 0.0) : null,
      imageUrl: json['image_url']?.toString(),
      likesCount: parseInt(json['likes_count'], 0),
      dislikesCount: parseInt(json['dislikes_count'], 0),
      userVote: parseBool(json['user_vote']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'osm_id': osmId,
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
      'is_verified': isVerified,
      'distance_km': distanceKm,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
      'user_vote': userVote,
    };
  }
}
