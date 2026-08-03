/// Participant summary inside a match (Player 1, Player 2, or Scorer)
class MatchParticipantModel {
  final String id;
  final String name;
  final String email;
  final int rating;
  final String? avatarUrl;
  final String? primarySport;
  final Map<String, int>? sportRatings;

  MatchParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.rating,
    this.avatarUrl,
    this.primarySport,
    this.sportRatings,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory MatchParticipantModel.fromJson(Map<String, dynamic> json) {
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

    return MatchParticipantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous',
      email: json['email'] as String? ?? '',
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 1200,
      avatarUrl: json['avatar_url'] as String?,
      primarySport: json['primary_sport'] as String?,
      sportRatings: parsedRatings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'rating': rating,
      'avatar_url': avatarUrl,
      'primary_sport': primarySport,
      'sport_ratings': sportRatings,
    };
  }
}

/// Match Data Model representing a match record from PostgreSQL `matches` table
class MatchModel {
  final String id;
  final String creatorId;
  final String player1Id;
  final String? player2Id;
  final bool player2Accepted;
  final String? scorerId;
  final bool scorerAccepted;
  final String sport; // 'pickleball', 'tennis', 'table_tennis'
  final String venueName;
  final String? location;
  final DateTime scheduledAt;
  final String status; // 'WAITING', 'READY', 'LIVE', 'FINISHED', 'CONFIRMED'
  final int totalSets;
  final int pointsToWinSet;
  final bool winByTwo;
  final String? winnerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final MatchParticipantModel? player1;
  final MatchParticipantModel? player2;
  final MatchParticipantModel? scorer;

  MatchModel({
    required this.id,
    required this.creatorId,
    required this.player1Id,
    this.player2Id,
    this.player2Accepted = false,
    this.scorerId,
    this.scorerAccepted = false,
    required this.sport,
    required this.venueName,
    this.location,
    required this.scheduledAt,
    required this.status,
    this.totalSets = 3,
    this.pointsToWinSet = 11,
    this.winByTwo = true,
    this.winnerId,
    this.createdAt,
    this.updatedAt,
    this.player1,
    this.player2,
    this.scorer,
  });

  /// Display helper for human-readable sport title
  String get sportDisplayName {
    switch (sport.toLowerCase()) {
      case 'pickleball':
        return 'Pickleball';
      case 'tennis':
        return 'Tennis';
      case 'table_tennis':
        return 'Table Tennis';
      default:
        return sport;
    }
  }

  /// Display helper for sets title
  String get setsFormatTitle => totalSets == 1 ? '1 Set' : 'Best of $totalSets Sets';

  /// Display helper for target points title
  String get pointsFormatTitle => '$pointsToWinSet Points';

  /// Display helper for win margin title
  String get winMarginTitle => winByTwo ? 'Win by 2 Points' : 'Standard';

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      player1Id: json['player1_id'] as String? ?? '',
      player2Id: json['player2_id'] as String?,
      player2Accepted: json['player2_accepted'] as bool? ?? false,
      scorerId: json['scorer_id'] as String?,
      scorerAccepted: json['scorer_accepted'] as bool? ?? false,
      sport: json['sport'] as String? ?? 'pickleball',
      venueName: json['venue_name'] as String? ?? '',
      location: json['location'] as String?,
      scheduledAt: DateTime.tryParse('${json['scheduled_at']}') ?? DateTime.now(),
      status: json['status'] as String? ?? 'WAITING',
      totalSets: json['total_sets'] is int ? json['total_sets'] as int : int.tryParse('${json['total_sets']}') ?? 3,
      pointsToWinSet: json['points_to_win_set'] is int ? json['points_to_win_set'] as int : int.tryParse('${json['points_to_win_set']}') ?? 11,
      winByTwo: json['win_by_two'] as bool? ?? true,
      winnerId: json['winner_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse('${json['updated_at']}') : null,
      player1: json['player1'] != null && json['player1'] is Map<String, dynamic>
          ? MatchParticipantModel.fromJson(json['player1'] as Map<String, dynamic>)
          : null,
      player2: json['player2'] != null && json['player2'] is Map<String, dynamic>
          ? MatchParticipantModel.fromJson(json['player2'] as Map<String, dynamic>)
          : null,
      scorer: json['scorer'] != null && json['scorer'] is Map<String, dynamic>
          ? MatchParticipantModel.fromJson(json['scorer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player2_accepted': player2Accepted,
      'scorer_id': scorerId,
      'scorer_accepted': scorerAccepted,
      'sport': sport,
      'venue_name': venueName,
      'location': location,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status,
      'total_sets': totalSets,
      'points_to_win_set': pointsToWinSet,
      'win_by_two': winByTwo,
      'winner_id': winnerId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (player1 != null) 'player1': player1!.toJson(),
      if (player2 != null) 'player2': player2!.toJson(),
      if (scorer != null) 'scorer': scorer!.toJson(),
    };
  }
}
