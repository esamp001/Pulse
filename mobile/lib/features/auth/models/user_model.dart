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
  final String authProvider;
  final bool hasPassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.rating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.isOnboarded = false,
    this.primarySport = 'pickleball',
    this.avatarUrl,
    this.authProvider = 'email',
    this.hasPassword = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Getter to retrieve ONLY the user's first name for greetings
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Player';
    return trimmed.split(' ').first;
  }

  /// Formatted rating string (e.g. "1,200 ELO")
  String get formattedRating {
    final str = rating.toString();
    final formatted = str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted ELO';
  }

  /// Formatted win/loss record (e.g. "5W - 2L")
  String get recordText => '${wins}W - ${losses}L';

  /// Capitalized primary sport name (e.g. "Pickleball")
  String get formattedSport {
    if (primarySport.isEmpty) return 'Pickleball';
    return '${primarySport[0].toUpperCase()}${primarySport.substring(1)}';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final provider = json['auth_provider'] as String? ?? 'email';
    
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 1200,
      wins: json['wins'] is int ? json['wins'] as int : int.tryParse('${json['wins']}') ?? 0,
      losses: json['losses'] is int ? json['losses'] as int : int.tryParse('${json['losses']}') ?? 0,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      primarySport: json['primary_sport'] as String? ?? 'pickleball',
      avatarUrl: json['avatar_url'] as String?,
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
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
      'has_password': hasPassword,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
