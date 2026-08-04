class LeaderboardEntryModel {
  final int rank;
  final String id;
  final String name;
  final String? avatarUrl;
  final String sport;
  final int rating;
  final int wins;
  final int losses;
  final int totalMatches;
  final double winRate;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.rank,
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.sport,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.totalMatches,
    required this.winRate,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Anonymous Player',
      avatarUrl: json['avatar_url']?.toString(),
      sport: json['sport']?.toString() ?? 'pickleball',
      rating: (json['rating'] as num?)?.toInt() ?? 1200,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      totalMatches: (json['total_matches'] as num?)?.toInt() ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}

class LeaderboardResponseModel {
  final List<LeaderboardEntryModel> entries;
  final LeaderboardEntryModel? currentUserEntry;
  final String sport;
  final String category;
  final bool hasMore;
  final int limit;
  final int offset;

  const LeaderboardResponseModel({
    required this.entries,
    this.currentUserEntry,
    required this.sport,
    required this.category,
    this.hasMore = false,
    this.limit = 50,
    this.offset = 0,
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'] as List<dynamic>? ?? [];
    final entriesList = entriesRaw.map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>)).toList();
    LeaderboardEntryModel? currentUser;
    if (json['currentUserEntry'] != null) {
      currentUser = LeaderboardEntryModel.fromJson(json['currentUserEntry'] as Map<String, dynamic>);
    }
    return LeaderboardResponseModel(
      entries: entriesList,
      currentUserEntry: currentUser,
      sport: json['sport']?.toString() ?? 'all',
      category: json['category']?.toString() ?? 'elo',
      hasMore: json['hasMore'] == true,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
