import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../main.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../services/leaderboard_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final ScrollController _scrollController = ScrollController();

  String _selectedSport = 'all';
  String _selectedCategory = 'elo'; // 'elo', 'win_rate', 'matches'
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentOffset = 0;
  static const int _pageSize = 50;
  String? _errorMessage;

  List<LeaderboardEntryModel> _entries = [];
  LeaderboardEntryModel? _currentUserEntry;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static const List<Map<String, String>> _sports = [
    {'key': 'all', 'label': 'ALL SPORTS'},
    {'key': 'pickleball', 'label': 'PICKLEBALL'},
    {'key': 'table_tennis', 'label': 'TABLE TENNIS'},
    {'key': 'tennis', 'label': 'TENNIS'},
    {'key': 'badminton', 'label': 'BADMINTON'},
  ];

  static const List<Map<String, String>> _categories = [
    {'key': 'elo', 'label': 'ELO Rating'},
    {'key': 'win_rate', 'label': 'Win Rate'},
    {'key': 'matches', 'label': 'Matches'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreEntries();
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentOffset = 0;
      _hasMore = false;
    });

    try {
      final response = await _leaderboardService.fetchLeaderboard(
        sport: _selectedSport,
        category: _selectedCategory,
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _entries = response.entries;
          _currentUserEntry = response.currentUserEntry;
          _hasMore = response.hasMore;
          _currentOffset = response.entries.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreEntries() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _leaderboardService.fetchLeaderboard(
        sport: _selectedSport,
        category: _selectedCategory,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _entries.addAll(response.entries);
          _hasMore = response.hasMore;
          _currentOffset += response.entries.length;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSportSelected(String sportKey) {
    if (_selectedSport == sportKey) return;
    setState(() {
      _selectedSport = sportKey;
    });
    _loadLeaderboard();
  }

  void _onCategorySelected(String categoryKey) {
    if (_selectedCategory == categoryKey) return;
    setState(() {
      _selectedCategory = categoryKey;
    });
    _loadLeaderboard();
  }

  String _getMetricValueText(LeaderboardEntryModel entry) {
    switch (_selectedCategory) {
      case 'win_rate':
        return '${entry.winRate.toStringAsFixed(1)}%';
      case 'matches':
        return '${entry.totalMatches} Matches';
      case 'elo':
      default:
        return '${entry.rating} ELO';
    }
  }

  String _getMetricSubtext(LeaderboardEntryModel entry) {
    switch (_selectedCategory) {
      case 'win_rate':
        return '${entry.wins}W - ${entry.losses}L (${entry.totalMatches} matches)';
      case 'matches':
        return '${entry.wins} Wins • ${entry.losses} Losses';
      case 'elo':
      default:
        return '${entry.wins}W - ${entry.losses}L (${entry.winRate.toStringAsFixed(0)}% WR)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.getBackground(_isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSportFilterBar(),
            const SizedBox(height: 10),
            _buildCategoryTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _entries.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadLeaderboard,
                              color: PulseColors.accent,
                              backgroundColor: PulseColors.getSurface(_isDarkMode),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(bottom: 120),
                                child: Column(
                                  children: [
                                    if (_entries.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildPodiumSection(),
                                      const SizedBox(height: 16),
                                    ],
                                    if (_entries.length > 3) ...[
                                      _buildListHeader(),
                                      _buildRankingsList(),
                                    ],
                                    if (_isLoadingMore) ...[
                                      const SizedBox(height: 16),
                                      const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: PulseColors.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
            ),
            if (_currentUserEntry != null && !_isLoading) _buildPinnedCurrentUserBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rankings & Leaderboards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Top rated athletes across verified matches',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PulseColors.getTextSecondary(_isDarkMode),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadLeaderboard,
            icon: Icon(
              Icons.refresh_rounded,
              color: PulseColors.getTextPrimary(_isDarkMode),
              size: 22,
            ),
            tooltip: 'Refresh Rankings',
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _sports.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = _sports[index];
          final isSelected = _selectedSport == sport['key'];

          return ChoiceChip(
            label: Text(sport['label']!),
            selected: isSelected,
            onSelected: (_) => _onSportSelected(sport['key']!),
            selectedColor: PulseColors.primary,
            backgroundColor: PulseColors.getSurface(_isDarkMode),
            elevation: 0,
            pressElevation: 0,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? PulseColors.primary
                    : PulseColors.getBorder(_isDarkMode),
                width: 1.2,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? Colors.white : PulseColors.getTextSecondary(_isDarkMode),
              letterSpacing: 0.6,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: PulseColors.getSurface(_isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PulseColors.getBorder(_isDarkMode),
            width: 1.2,
          ),
        ),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onCategorySelected(cat['key']!),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isDarkMode ? const Color(0xFF2A3D42) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: PulseColors.getBorder(_isDarkMode),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      cat['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? PulseColors.getTextPrimary(_isDarkMode)
                            : PulseColors.getTextSecondary(_isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPodiumSection() {
    final topThree = _entries.take(3).toList();
    LeaderboardEntryModel? firstPlace;
    LeaderboardEntryModel? secondPlace;
    LeaderboardEntryModel? thirdPlace;

    if (topThree.isNotEmpty) firstPlace = topThree[0];
    if (topThree.length > 1) secondPlace = topThree[1];
    if (topThree.length > 2) thirdPlace = topThree[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place Podium
          Expanded(
            child: secondPlace != null
                ? _buildPodiumCard(
                    entry: secondPlace,
                    rank: 2,
                    badgeColor: const Color(0xFF9E9E9E), // Silver
                    badgeText: '2ND',
                    height: 170,
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 10),
          // 1st Place Podium
          Expanded(
            child: firstPlace != null
                ? _buildPodiumCard(
                    entry: firstPlace,
                    rank: 1,
                    badgeColor: const Color(0xFFFFB300), // Gold
                    badgeText: '1ST',
                    height: 195,
                    isFirst: true,
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 10),
          // 3rd Place Podium
          Expanded(
            child: thirdPlace != null
                ? _buildPodiumCard(
                    entry: thirdPlace,
                    rank: 3,
                    badgeColor: const Color(0xFFCD7F32), // Bronze
                    badgeText: '3RD',
                    height: 155,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required LeaderboardEntryModel entry,
    required int rank,
    required Color badgeColor,
    required String badgeText,
    required double height,
    bool isFirst = false,
  }) {
    final initial = entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'P';

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: isFirst
            ? (_isDarkMode ? const Color(0xFF1E2E32) : const Color(0xFFEAF5F7))
            : PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFirst ? PulseColors.accent : PulseColors.getBorder(_isDarkMode),
          width: isFirst ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Rank Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Avatar Circle
          Container(
            width: isFirst ? 48 : 42,
            height: isFirst ? 48 : 42,
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor,
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: isFirst ? 18 : 16,
                  fontWeight: FontWeight.w900,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
            ),
          ),

          // Player Name & Stats
          Column(
            children: [
              Text(
                entry.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                _getMetricValueText(entry),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isFirst ? PulseColors.accent : PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RUNNER UPS (#4+)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextSecondary(_isDarkMode),
              letterSpacing: 0.8,
            ),
          ),
          Text(
            _selectedCategory == 'win_rate'
                ? 'WIN RATE'
                : _selectedCategory == 'matches'
                    ? 'MATCHES'
                    : 'ELO SCORE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextSecondary(_isDarkMode),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    final runnerUps = _entries.skip(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: runnerUps.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = runnerUps[index];
        return _buildRankItemTile(entry);
      },
    );
  }

  Widget _buildRankItemTile(LeaderboardEntryModel entry) {
    final initial = entry.name.isNotEmpty ? entry.name[0].toUpperCase() : 'P';
    final isMe = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? PulseColors.primary.withValues(alpha: 0.15)
            : PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? PulseColors.accent : PulseColors.getBorder(_isDarkMode),
          width: isMe ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isMe ? PulseColors.accent : PulseColors.getTextSecondary(_isDarkMode),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Player Avatar Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PulseColors.getBackground(_isDarkMode),
              shape: BoxShape.circle,
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player Name & Subtext
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PulseColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getMetricSubtext(entry),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PulseColors.getTextSecondary(_isDarkMode),
                  ),
                ),
              ],
            ),
          ),

          // Metric Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PulseColors.getBackground(_isDarkMode),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.0,
              ),
            ),
            child: Text(
              _getMetricValueText(entry),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: PulseColors.getTextPrimary(_isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedCurrentUserBar() {
    final entry = _currentUserEntry!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(_isDarkMode),
        border: Border(
          top: BorderSide(
            color: PulseColors.getBorder(_isDarkMode),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PulseColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'YOUR RANK #${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getMetricSubtext(entry),
                    style: TextStyle(
                      fontSize: 11,
                      color: PulseColors.getTextSecondary(_isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _getMetricValueText(entry),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: PulseColors.getTextPrimary(_isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: PulseColors.accent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching Leaderboard...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: PulseColors.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load rankings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: PulseColors.getTextPrimary(_isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 56,
            color: PulseColors.getTextSecondary(_isDarkMode),
          ),
          const SizedBox(height: 12),
          Text(
            'No Leaderboard Data Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: PulseColors.getTextPrimary(_isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Play verified matches to climb the leaderboard!',
            style: TextStyle(
              fontSize: 13,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
