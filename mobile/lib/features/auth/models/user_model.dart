/// User Data Model representing a user from the backend `users` table
class UserModel {
  final String id;
  final String name;
  final String email;
  final int rating;
  final int wins;
  final int losses;
  final bool isOnboarded;
  final String primarySport;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? phoneNumber;
  final String? location;
  final String? bio;
  final String authProvider;
  final bool hasPassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final Map<String, int> sportRatings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.rating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.isOnboarded = false,
    this.primarySport = 'pickleball',
    Map<String, int>? sportRatings,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.phoneNumber,
    this.location,
    this.bio,
    this.authProvider = 'email',
    this.hasPassword = true,
    this.createdAt,
    this.updatedAt,
  }) : sportRatings = sportRatings ?? {primarySport.toLowerCase(): rating};

  /// Getter to retrieve ONLY the user's first name for greetings
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Player';
    return trimmed.split(' ').first;
  }

  /// Formatted rating string (e.g. "1,200 ELO")
  String get formattedRating => getFormattedRatingForSport(primarySport);

  /// Get rating for a specific sport (fallback to primary rating)
  int getRatingForSport(String sport) {
    final key = sport.toLowerCase();
    if (sportRatings.containsKey(key)) {
      return sportRatings[key]!;
    }
    return rating;
  }

  /// Formatted rating string for a specific sport (e.g. "1,200 ELO")
  String getFormattedRatingForSport(String sport) {
    final val = getRatingForSport(sport);
    final str = val.toString();
    final formatted = str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted ELO';
  }

  /// List of capitalized configured sports
  List<String> get configuredSports {
    if (sportRatings.isEmpty) {
      return [formattedSport];
    }
    return sportRatings.keys.map((s) {
      if (s.isEmpty) return 'Pickleball';
      final clean = s.replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final words = clean.split(' ');
      return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }).toList();
  }

  /// Formatted win/loss record (e.g. "5W - 2L")
  String get recordText => '${wins}W - ${losses}L';

  /// Capitalized primary sport name (e.g. "Pickleball")
  String get formattedSport {
    if (primarySport.isEmpty) return 'Pickleball';
    return '${primarySport[0].toUpperCase()}${primarySport.substring(1)}';
  }

  /// Copy user model with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? rating,
    int? wins,
    int? losses,
    bool? isOnboarded,
    String? primarySport,
    Map<String, int>? sportRatings,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? phoneNumber,
    String? location,
    String? bio,
    String? authProvider,
    bool? hasPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      primarySport: primarySport ?? this.primarySport,
      sportRatings: sportRatings ?? Map<String, int>.from(this.sportRatings),
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      authProvider: authProvider ?? this.authProvider,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final provider = json['auth_provider'] as String? ?? 'email';
    
    Map<String, int>? parsedRatings;
    final rawRatings = json['sport_ratings'] ?? json['sportRatings'];
    if (rawRatings is Map) {
      parsedRatings = {};
      rawRatings.forEach((k, v) {
        final keyStr = k.toString().toLowerCase();
        final intVal = v is int ? v : int.tryParse('$v') ?? 1200;
        parsedRatings![keyStr] = intVal;
      });
    }

    final pSport = json['primary_sport'] as String? ?? 'pickleball';
    final baseRating = json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 1200;

    if (parsedRatings == null || parsedRatings.isEmpty) {
      parsedRatings = {pSport.toLowerCase(): baseRating};
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rating: baseRating,
      wins: json['wins'] is int ? json['wins'] as int : int.tryParse('${json['wins']}') ?? 0,
      losses: json['losses'] is int ? json['losses'] as int : int.tryParse('${json['losses']}') ?? 0,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      primarySport: pSport,
      sportRatings: parsedRatings,
      avatarUrl: json['avatar_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      authProvider: provider,
      hasPassword: json['has_password'] as bool? ?? (provider == 'email'),
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse('${json['updated_at']}') : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'rating': rating,
      'wins': wins,
      'losses': losses,
      'is_onboarded': isOnboarded,
      'primary_sport': primarySport,
      'sport_ratings': sportRatings,
      'avatar_url': avatarUrl,
      'cover_photo_url': coverPhotoUrl,
      'phone_number': phoneNumber,
      'location': location,
      'bio': bio,
      'auth_provider': authProvider,
      'has_password': hasPassword,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
