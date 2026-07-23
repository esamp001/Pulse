/// User Data Model representing a user from the backend `users` table
class UserModel {
  final String id;
  final String name;
  final String email;
  final int rating;
  final int wins;
  final int losses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.rating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Getter to retrieve ONLY the user's first name for greetings
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Player';
    return trimmed.split(' ').first;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 1200,
      wins: json['wins'] is int ? json['wins'] as int : int.tryParse('${json['wins']}') ?? 0,
      losses: json['losses'] is int ? json['losses'] as int : int.tryParse('${json['losses']}') ?? 0,
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
