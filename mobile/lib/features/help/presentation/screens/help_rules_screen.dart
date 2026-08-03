import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';

class HelpRulesScreen extends StatefulWidget {
  final bool isDarkMode;

  const HelpRulesScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<HelpRulesScreen> createState() => _HelpRulesScreenState();
}

class _HelpRulesScreenState extends State<HelpRulesScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_HelpItem> _allHelpItems = const [
    _HelpItem(
      category: 'PICKLEBALL',
      categoryDisplayName: 'Pickleball',
      icon: Icons.sports_tennis_rounded,
      title: 'Pickleball Scoring & Basic Rules',
      summary: '11-point games, win by 2, underhand serves, and the Kitchen zone.',
      sections: [
        _HelpSection(
          heading: 'Serving Rules',
          body:
              'The serve must be executed underhand with paddle contact made below the waist. The serve must travel diagonally across the net into the opponent’s service court, clearing the non-volley zone (Kitchen).',
        ),
        _HelpSection(
          heading: 'The Non-Volley Zone (The Kitchen)',
          body:
              'The Kitchen is the 7-foot zone on both sides of the net. Players cannot volley (hit the ball in mid-air) while standing inside or stepping on the Kitchen line.',
        ),
        _HelpSection(
          heading: 'Two-Bounce Rule',
          body:
              'When the ball is served, the receiving team must let it bounce before returning it. Then, the serving team must let the return bounce before hitting it. After two bounces, players can volley or play off the bounce.',
        ),
        _HelpSection(
          heading: 'Scoring Format',
          body:
              'Games are played to 11 points, and a team must win by 2 points. Points are scored on the serving team’s serve in side-out scoring or on every rally in rally scoring.',
        ),
      ],
    ),
    _HelpItem(
      category: 'TENNIS',
      categoryDisplayName: 'Tennis',
      icon: Icons.sports_baseball_rounded,
      title: 'Tennis Scoring & Match Structure',
      summary: '15-30-40 game points, Deuce/Advantage, sets, and tiebreaks.',
      sections: [
        _HelpSection(
          heading: 'Game Point System',
          body:
              'Points progress as 0 (Love), 15, 30, 40, and Game point. If both players reach 40, the score is called Deuce.',
        ),
        _HelpSection(
          heading: 'Deuce & Advantage',
          body:
              'At Deuce (40-40), a player must win 2 consecutive points to win the game. The first point won gives that player Advantage (Ad). Winning the next point secures the game.',
        ),
        _HelpSection(
          heading: 'Set & Tiebreak Rules',
          body:
              'A standard set is won by the first player to win 6 games by a margin of 2 games. If the set reaches 6-6, a 7-point Tiebreak is played to decide the set winner.',
        ),
        _HelpSection(
          heading: 'Match Format',
          body:
              'Matches in Rally are played as Best of 3 sets or single-set sprint matches depending on host settings.',
        ),
      ],
    ),
    _HelpItem(
      category: 'TABLE_TENNIS',
      categoryDisplayName: 'Table Tennis',
      icon: Icons.sports_kabaddi_rounded,
      title: 'Table Tennis Scoring & Service',
      summary: '11-point games, service rotation every 2 points, best of 3/5 sets.',
      sections: [
        _HelpSection(
          heading: 'Game & Set Scoring',
          body:
              'A game is won by the first player to reach 11 points. If the score ties at 10-10 (Deuce), the game continues until one player leads by 2 points.',
        ),
        _HelpSection(
          heading: 'Service Rotation',
          body:
              'Service alternates between players every 2 points. At 10-10, service alternates after every single point until the game is completed.',
        ),
        _HelpSection(
          heading: 'Service Execution',
          body:
              'The ball must rest freely on an open palm, be tossed vertically at least 6 inches, and be struck so it bounces first on the server’s side, then on the receiver’s side.',
        ),
      ],
    ),
    _HelpItem(
      category: 'ELO',
      categoryDisplayName: 'Rating & ELO',
      icon: Icons.auto_graph_rounded,
      title: 'Rally Per-Sport ELO Rating Mechanics',
      summary: 'How ELO ratings are tracked independently per sport and adjusted after matches.',
      sections: [
        _HelpSection(
          heading: 'Per-Sport Rating Separation',
          body:
              'Your skill rating (ELO) is tracked independently for each sport (Pickleball, Tennis, Table Tennis). Winning a Tennis match only updates your Tennis rating.',
        ),
        _HelpSection(
          heading: 'Starting Ratings',
          body:
              'New players start with a baseline ELO rating of 1200, which adjusts dynamically as matches are confirmed and verified.',
        ),
        _HelpSection(
          heading: 'Rating Calculation Formula',
          body:
              'ELO changes depend on the rating difference between opponents. Defeating a higher-rated player yields a larger ELO gain, while losing to a lower-rated player results in a larger rating drop.',
        ),
      ],
    ),
    _HelpItem(
      category: 'FLOW',
      categoryDisplayName: 'Match Flow',
      icon: Icons.verified_user_rounded,
      title: 'Match Creation, Roles & Verification',
      summary: 'Host creation, Player 2 invitations, Scorekeeper duties, and score verification.',
      sections: [
        _HelpSection(
          heading: 'Match Roles',
          body:
              '• Host: Creates match lobby, court venue, and rule set.\n• Player 2: Invited opponent who accepts the match.\n• Scorer: Assigned official scorekeeper responsible for recording live points.',
        ),
        _HelpSection(
          heading: 'Live Scoring & Updates',
          body:
              'The assigned Scorer records live points in real time. Live scores stream to all participants via Socket.IO events instantly.',
        ),
        _HelpSection(
          heading: 'Match Verification & ELO Processing',
          body:
              'Once the final point is scored, the match result is finalized and logged into player history, automatically updating official ratings.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HelpItem> get _filteredHelpItems {
    return _allHelpItems.where((item) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          item.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return matchesCategory;

      final matchesQuery = item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.sections.any((s) =>
              s.heading.toLowerCase().contains(query) ||
              s.body.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final filtered = _filteredHelpItems;

    return Scaffold(
      backgroundColor: PulseColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Flat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: PulseColors.getSurface(isDark),
                border: Border(
                  bottom: BorderSide(
                    color: PulseColors.getBorder(isDark),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  PulseBackButton(isDarkMode: isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Sport Rules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: PulseColors.getTextPrimary(isDark),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Scoring guides, ELO ratings & match workflows',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Category Filters
            Container(
              padding: const EdgeInsets.all(16.0),
              color: PulseColors.getBackground(isDark),
              child: Column(
                children: [
                  // Search TextField
                  Container(
                    decoration: BoxDecoration(
                      color: PulseColors.getSurface(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: PulseColors.getBorder(isDark),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontSize: 14,
                        color: PulseColors.getTextPrimary(isDark),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search rules, scoring, ELO ratings...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: PulseColors.getTextSecondary(isDark),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: PulseColors.getTextSecondary(isDark),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: PulseColors.getTextSecondary(isDark),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Guides', isDark),
                        _buildFilterChip('PICKLEBALL', 'Pickleball', isDark),
                        _buildFilterChip('TENNIS', 'Tennis', isDark),
                        _buildFilterChip('TABLE_TENNIS', 'Table Tennis', isDark),
                        _buildFilterChip('ELO', 'Rating & ELO', isDark),
                        _buildFilterChip('FLOW', 'Match Flow', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No matching guides found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PulseColors.getTextPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for another rule or sport',
                            style: TextStyle(
                              fontSize: 12,
                              color: PulseColors.getTextSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildHelpCard(filtered[index], isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String categoryKey, String label, bool isDark) {
    final isSelected = _selectedCategory == categoryKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = categoryKey),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? PulseColors.primary
                : PulseColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? PulseColors.primary
                  : PulseColors.getBorder(isDark),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : PulseColors.getTextPrimary(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(_HelpItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: PulseColors.getBorder(isDark).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PulseColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PulseColors.accent.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Icon(
              item.icon,
              color: PulseColors.accent,
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextPrimary(isDark),
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              item.summary,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: PulseColors.getTextSecondary(isDark),
              ),
            ),
          ),
          children: item.sections.asMap().entries.map((entry) {
            final idx = entry.key;
            final section = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (idx > 0)
                  Divider(
                    height: 16,
                    thickness: 0.8,
                    color: PulseColors.getBorder(isDark).withValues(alpha: 0.4),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: PulseColors.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.heading,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: PulseColors.getTextPrimary(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          section.body,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HelpItem {
  final String category;
  final String categoryDisplayName;
  final IconData icon;
  final String title;
  final String summary;
  final List<_HelpSection> sections;

  const _HelpItem({
    required this.category,
    required this.categoryDisplayName,
    required this.icon,
    required this.title,
    required this.summary,
    required this.sections,
  });
}

class _HelpSection {
  final String heading;
  final String body;

  const _HelpSection({
    required this.heading,
    required this.body,
  });
}
