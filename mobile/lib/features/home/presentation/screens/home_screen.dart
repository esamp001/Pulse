import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_top_bar.dart';
import '../../../../core/widgets/pulse_bottom_nav_bar.dart';
import '../../../../core/widgets/pulse_widget_card.dart';
import '../../../../main.dart';

import '../../../auth/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../matches/models/match_model.dart';
import '../../../matches/presentation/screens/create_match_screen.dart';
import '../../../matches/presentation/screens/match_lobby_screen.dart';
import '../../../matches/presentation/widgets/match_invitation_snackbar.dart';
import '../../../matches/services/match_service.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  UserModel? _user;
  bool _isLoadingUser = false;
  MatchModel? _activeMatch;
  Timer? _pollTimer;
  String? _dismissedInvitationMatchId;
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? AuthService.currentUser;

    if (_user == null && AuthService.currentToken != null) {
      _loadCurrentUserProfile();
    }
    _fetchActiveMatch();
    _startPollingActiveMatch();
  }

  void _startPollingActiveMatch() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _fetchActiveMatch();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool get _isInvitationPending {
    if (_activeMatch == null) return false;
    final currentUserId = _user?.id ?? AuthService.currentUser?.id;
    if (currentUserId == null) return false;
    if (_activeMatch!.id == _dismissedInvitationMatchId) return false;
    if (_activeMatch!.creatorId == currentUserId) return false;

    final isPlayer2 = _activeMatch!.player2Id == currentUserId && !_activeMatch!.player2Accepted;
    final isScorer = _activeMatch!.scorerId == currentUserId && !_activeMatch!.scorerAccepted;

    return isPlayer2 || isScorer;
  }

  String get _invitedUserRoleLabel {
    final currentUserId = _user?.id ?? AuthService.currentUser?.id;
    if (_activeMatch?.scorerId == currentUserId) {
      return 'Neutral Scorer';
    }
    return 'Player 2 (Opponent)';
  }

  Future<void> _acceptMatchInvitation() async {
    if (_activeMatch == null) return;
    final matchToJoin = _activeMatch!;
    setState(() {
      _dismissedInvitationMatchId = matchToJoin.id;
    });
    try {
      final updatedMatch = await _matchService.acceptInvitation(matchToJoin.id);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MatchLobbyScreen(match: updatedMatch),
          ),
        ).then((_) => _fetchActiveMatch());
      }
    } catch (_) {
      _fetchActiveMatch();
    }
  }

  Future<void> _declineMatchInvitation() async {
    if (_activeMatch == null) return;
    final matchId = _activeMatch!.id;
    setState(() {
      _dismissedInvitationMatchId = matchId;
      _activeMatch = null;
    });
    try {
      await _matchService.declineInvitation(matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match invitation declined.'),
            backgroundColor: PulseColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
    _fetchActiveMatch();
  }

  // fetches active match and updates the state if there is an active match 
  Future<void> _fetchActiveMatch() async {
    try {
      final match = await _matchService.getActiveMatch();
      if (mounted) {
        setState(() {
          _activeMatch = match;
        });
      }
    } catch (_) {}
  }

  // loads current user profile
  Future<void> _loadCurrentUserProfile() async {
    setState(() => _isLoadingUser = true);

    try {
      final fetchedUser = await _authService.fetchCurrentUser();
      if (mounted) {
        setState(() {
          _user = fetchedUser;
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _openAvatarSideModal() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    if (index == 2) {
      _onCompeteNowPressed();
    }
  }

  void _onCompeteNowPressed() async {
    await _fetchActiveMatch();

    if (!mounted) return;

    if (_activeMatch != null) {
      final activeMatch = _activeMatch!;
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: PulseColors.getSurface(_isDarkMode),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: PulseColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Active Room Exists',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                  ),
                ),
              ],
            ),
            content: Text(
              'You currently have an active match lobby (${activeMatch.sportDisplayName}). Only 1 active room is allowed at a time.',
              style: TextStyle(
                fontSize: 14,
                color: PulseColors.getTextSecondary(_isDarkMode),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(dialogContext).pop();
                  try {
                    await _matchService.exitMatch(activeMatch.id);
                    if (mounted) {
                      setState(() => _activeMatch = null);
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) => const CreateMatchScreen(),
                        ),
                      ).then((_) => _fetchActiveMatch());
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: PulseColors.error,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Exit Active Room',
                  style: TextStyle(color: PulseColors.error, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchLobbyScreen(match: activeMatch),
                    ),
                  ).then((_) => _fetchActiveMatch());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Return to Room'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateMatchScreen(),
        ),
      ).then((_) => _fetchActiveMatch());
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.firstName ?? 'Elle';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: PulseColors.getBackground(_isDarkMode),
      drawer: _buildAvatarSideModal(context),
      appBar: PulseTopBar(
        userName: displayName,
        unreadCount: 2,
        isDarkMode: _isDarkMode,
        onAvatarTap: _openAvatarSideModal,

        onInboxTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Inbox & Invitations'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildHomeContent(displayName),
          _buildPlaceholderTab('Match History'),
          _buildHomeContent(displayName), // Compete tab focus
          _buildPlaceholderTab('Rankings & Leaderboards'),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isInvitationPending && _activeMatch != null)
            MatchInvitationSnackbar(
              match: _activeMatch!,
              currentUserRoleLabel: _invitedUserRoleLabel,
              isDarkMode: _isDarkMode,
              onAccept: _acceptMatchInvitation,
              onDecline: _declineMatchInvitation,
            ),
          PulseBottomNavBar(
            currentIndex: _currentBottomNavIndex,
            onTap: _onBottomNavTapped,
          ),
        ],
      ),
    );
  }

  /// Modern Minimalist Bento Grid Home Screen Content
  Widget _buildHomeContent(String firstName) {
    final ratingText = _user?.formattedRating ?? '1,200 ELO';
    final recordText = _user?.recordText ?? '0W - 0L';
    final sportText = _user?.formattedSport ?? 'Pickleball';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Personalized Greeting Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Welcome back, $firstName',
                            style: TextStyle(

                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isLoadingUser) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PulseColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready for your next verified match?',
                      style: TextStyle(
                        fontSize: 13,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Athlete Quick Stats Bar (Minimalist Pills)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatPill(
                  Icons.emoji_events_rounded,
                  ratingText,
                  PulseColors.accent,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  Icons.bolt_rounded,
                  recordText,
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  Icons.sports_tennis_rounded,
                  sportText,
                  const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Dynamic Featured Hero Action Card ("COMPETE NOW" vs "RETURN TO ROOM")
          PulseWidgetCard(
            title: _activeMatch == null ? 'Compete Now' : 'Active Match Lobby',
            subtitle: _activeMatch == null
                ? 'Create or join a rated match'
                : '${_activeMatch!.sportDisplayName} • ${_activeMatch!.status == 'READY' ? 'Ready to play' : 'Waiting for participants'}',
            pillText: _activeMatch == null ? 'RATED' : 'LIVE ROOM',
            onTap: _onCompeteNowPressed,
            isDarkMode: _isDarkMode,
            customContent: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: PulseColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeMatch == null ? 'START A MATCH' : 'RETURN TO ROOM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: Image.asset(
                      'assets/images/find_court.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.bolt_rounded,
                        size: 40,
                        color: PulseColors.accent,
                      ),

                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Section Title: Utility Actions
          Text(
            'Utility Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextPrimary(_isDarkMode),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // 5. Bento Grid Layout (Ultra-Modern Widget-Style Cards via PulseWidgetCard)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              // 1. Scan QR -> Soft Lilac / Purple Pastel (Card 1)
              PulseWidgetCard(
                imagePath: 'assets/images/scan_qr.png',
                title: 'Scan QR',
                subtitle: 'Join Room',
                pillText: 'FAST',
                backgroundColor: const Color(0xFFF3E5F5),
                isDarkMode: _isDarkMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening QR Scanner')),
                  );
                },
              ),
              // 2. Find Courts -> Soft Powder Blue Pastel (Card 2)
              PulseWidgetCard(
                imagePath: 'assets/images/find_court.png',
                title: 'Find Courts',
                subtitle: 'Locate Courts',
                pillText: 'NEARBY',
                backgroundColor: const Color(0xFFD6E9FE),
                isDarkMode: _isDarkMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Locating nearby courts...')),
                  );
                },
              ),
              // 3. Officiate -> Soft Warm Coral / Peach Pastel (Card 3)
              PulseWidgetCard(
                imagePath: 'assets/images/officiate.png',
                title: 'Officiate',
                subtitle: 'Neutral Ref',
                pillText: 'LIVE',
                backgroundColor: const Color(0xFFFFE0D6),
                isDarkMode: _isDarkMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Officiate Mode')),
                  );
                },
              ),
              // 4. Log Practice -> Soft Butter Yellow Pastel (Card 4)
              PulseWidgetCard(
                imagePath: 'assets/images/all_balls.png',
                title: 'Log Practice',
                subtitle: 'Unrated Drills',
                pillText: 'DRILLS',
                backgroundColor: const Color(0xFFF9EAB8),
                isDarkMode: _isDarkMode,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logging practice session...'),
                    ),
                  );
                },
              ),
            ],
          ),



          const SizedBox(height: 24),

          // 6. Featured Tournament / Event Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PulseColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: PulseColors.accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOCAL LEAGUES & TOURNAMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: PulseColors.getTextSecondary(_isDarkMode),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '10K Summer Ladder Cup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: PulseColors.getTextSecondary(_isDarkMode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7. Community Pulse / Nearby Challenges Section
          Text(
            'Community Pulse',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextPrimary(_isDarkMode),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.8,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: PulseColors.primary.withValues(
                        alpha: 0.2,
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: PulseColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open Doubles Lobby Nearby',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                          ),
                          Text(
                            'Need 1 player @ BGC Courts • 1.2 km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Joined open lobby invitation!'),
                          ),
                        );
                      },
                      child: const Text(
                        'JOIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: PulseColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: PulseColors.getBorder(_isDarkMode)),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marcus D. defeated Dave K.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                          ),
                          Text(
                            'Score: 2-1 (11-9, 8-11, 11-7) • +12 ELO',
                            style: TextStyle(
                              fontSize: 12,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PulseColors.getBorder(_isDarkMode),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PulseColors.getTextPrimary(_isDarkMode),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: PulseColors.accent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PulseColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon in the next module release.',
            style: TextStyle(color: PulseColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSideModal(BuildContext context) {
    final fullName = _user?.name ?? 'Ellejun Apresto Sampaga';
    final email = _user?.email ?? 'ellejunsampaga@gmail.com';
    final initials = _user?.firstName != null && _user!.firstName.isNotEmpty
        ? _user!.firstName[0].toUpperCase()
        : 'E';

    return Drawer(
      backgroundColor: PulseColors.getSurface(_isDarkMode),
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar of Side Modal: Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile & Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: PulseColors.getTextSecondary(_isDarkMode),
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: PulseColors.getBorder(_isDarkMode)),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Header Card (Horizontal Pill Layout matching user design)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.getBackground(_isDarkMode),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: PulseColors.getBorder(_isDarkMode),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar Circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: PulseColors.getSurface(_isDarkMode),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PulseColors.getBorder(_isDarkMode),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: PulseColors.getTextPrimary(
                                    _isDarkMode,
                                  ),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & Email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: PulseColors.getTextPrimary(
                                      _isDarkMode,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: PulseColors.getTextSecondary(
                                      _isDarkMode,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Athlete Quick Stats
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.getSurface(_isDarkMode),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PulseColors.getBorder(_isDarkMode),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDrawerStatItem(
                            'ELO',
                            _user != null ? '${_user!.rating}' : '1,200',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: PulseColors.getBorder(_isDarkMode),
                          ),
                          _buildDrawerStatItem(
                            'RECORD',
                            _user != null
                                ? '${_user!.wins}W-${_user!.losses}L'
                                : '0W-0L',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: PulseColors.getBorder(_isDarkMode),
                          ),
                          _buildDrawerStatItem('WIN RATE', '100%'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dark Mode Toggle Switch (Standard Side Drawer Setting)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.getSurface(_isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PulseColors.getBorder(_isDarkMode),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PulseColors.getBackground(_isDarkMode),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isDarkMode
                                  ? Icons.nights_stay_rounded
                                  : Icons.wb_sunny_outlined,
                              size: 18,
                              color: _isDarkMode
                                  ? PulseColors.secondary
                                  : PulseColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PulseColors.getTextPrimary(
                                      _isDarkMode,
                                    ),
                                  ),
                                ),
                                Text(
                                  _isDarkMode
                                      ? 'Dark theme active'
                                      : 'Light theme active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PulseColors.getTextSecondary(
                                      _isDarkMode,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDarkMode,
                            activeTrackColor: PulseColors.accent,
                            onChanged: (val) {
                              themeModeNotifier.value = val
                                  ? ThemeMode.dark
                                  : ThemeMode.light;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Quick Settings Menu Items
                    _buildDrawerMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update details & photo',
                      onTap: () {},
                    ),
                    _buildDrawerMenuItem(
                      icon: Icons.sports_tennis_rounded,
                      title: 'Sport Preferences',
                      subtitle: 'Pickleball & Tennis rules',
                      onTap: () {},
                    ),
                    _buildDrawerMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Match invites & scores',
                      onTap: () {},
                    ),
                    _buildDrawerMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Rules',
                      subtitle: 'Scoring guides & support',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Modern Log Out Section
            const Divider(height: 1, color: PulseColors.border),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutConfirmationDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.error.withValues(alpha: 0.08),
                    foregroundColor: PulseColors.error,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: PulseColors.getTextSecondary(_isDarkMode),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: PulseColors.getTextPrimary(_isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? PulseColors.secondary.withValues(alpha: 0.15)
                      : PulseColors.primary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: _isDarkMode
                      ? PulseColors.secondary
                      : PulseColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PulseColors.border,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); // Close drawer if open
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 5),
        backgroundColor: PulseColors.getSurface(_isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: PulseColors.getBorder(_isDarkMode),
            width: 1.0,
          ),
        ),
        elevation: 0,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PulseColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: PulseColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log out of Rally?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Confirm to end session',
                    style: TextStyle(
                      fontSize: 11,
                      color: PulseColors.getTextSecondary(_isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'LOG OUT',
          textColor: PulseColors.error,
          onPressed: () async {
            messenger.hideCurrentSnackBar();
            await AuthService.logout();
            if (mounted) {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
    );
  }

  void _showPasswordSetupModal(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    final isSocialUser =
        _user?.authProvider != null && _user!.authProvider != 'email';
    final hasExistingPassword = _user?.hasPassword ?? (!isSocialUser);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: PulseColors.getSurface(_isDarkMode),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: PulseColors.getBorder(_isDarkMode),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PulseColors.getTextSecondary(
                            _isDarkMode,
                          ).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PulseColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasExistingPassword
                                ? Icons.lock_reset_rounded
                                : Icons.enhanced_encryption_rounded,
                            color: PulseColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasExistingPassword
                                    ? 'Change Password'
                                    : 'Create Rally Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: PulseColors.getTextPrimary(
                                    _isDarkMode,
                                  ),
                                ),
                              ),
                              Text(
                                hasExistingPassword
                                    ? 'Update your password for security'
                                    : 'Set up a password for direct email sign-in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PulseColors.getTextSecondary(
                                    _isDarkMode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Social Account Connection Info Pill (If Social Login)
                    if (isSocialUser) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.getBackground(_isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PulseColors.getBorder(_isDarkMode),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.g_mobiledata_rounded,
                              color: PulseColors.accent,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connected via Social Auth (${_user?.email ?? ''})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: PulseColors.getTextPrimary(
                                    _isDarkMode,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1. Current Password Field (ONLY shown if user already has a password)
                    if (hasExistingPassword) ...[
                      Text(
                        'Current Password',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        enabled: !isSubmitting,
                        style: TextStyle(
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          hintStyle: TextStyle(
                            color: PulseColors.getTextSecondary(
                              _isDarkMode,
                            ).withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setModalState(
                              () => obscureCurrent = !obscureCurrent,
                            ),
                          ),
                          filled: true,
                          fillColor: PulseColors.getBackground(_isDarkMode),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: PulseColors.getBorder(_isDarkMode),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. New Password Field
                    Text(
                      hasExistingPassword ? 'New Password' : 'Create Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !isSubmitting,
                      style: TextStyle(
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter new password (min. 6 chars)',
                        hintStyle: TextStyle(
                          color: PulseColors.getTextSecondary(
                            _isDarkMode,
                          ).withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setModalState(() => obscureNew = !obscureNew),
                        ),
                        filled: true,
                        fillColor: PulseColors.getBackground(_isDarkMode),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: PulseColors.getBorder(_isDarkMode),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Confirm New Password Field
                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !isSubmitting,
                      style: TextStyle(
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Re-enter password',
                        hintStyle: TextStyle(
                          color: PulseColors.getTextSecondary(
                            _isDarkMode,
                          ).withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                        filled: true,
                        fillColor: PulseColors.getBackground(_isDarkMode),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: PulseColors.getBorder(_isDarkMode),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final currentPass = currentPasswordController
                                    .text
                                    .trim();
                                final newPass = newPasswordController.text
                                    .trim();
                                final confirmPass = confirmPasswordController
                                    .text
                                    .trim();

                                if (hasExistingPassword &&
                                    currentPass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your current password',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPass.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters long',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPass != confirmPass) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                    ),
                                  );
                                  return;
                                }

                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(modalContext);
                                setModalState(() => isSubmitting = true);

                                try {
                                  final updatedUser = await _authService
                                      .updatePassword(
                                        currentPassword: hasExistingPassword
                                            ? currentPass
                                            : null,
                                        newPassword: newPass,
                                      );

                                  if (mounted) {
                                    setState(() => _user = updatedUser);
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          hasExistingPassword
                                              ? 'Password updated successfully!'
                                              : 'Rally password created! You can now log in with email/password.',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF4CAF50,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                hasExistingPassword
                                    ? 'Update Password'
                                    : 'Create Password',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final fullName = _user?.name ?? 'Ellejun Apresto Sampaga';
    final email = _user?.email ?? 'ellejunsampaga@gmail.com';
    final initials = _user?.firstName != null && _user!.firstName.isNotEmpty
        ? _user!.firstName[0].toUpperCase()
        : 'E';
    final ratingText = _user?.formattedRating ?? '1,200 ELO';
    final recordText = _user?.recordText ?? '5W-1L';
    final sportText = _user?.formattedSport ?? 'Pickleball';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          // 1. Prominent Hero Avatar & User Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.8,
              ),
            ),
            child: Column(
              children: [
                // Prominent Centered Avatar with Camera Edit Badge
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PulseColors.accent, PulseColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PulseColors.accent,
                          width: 2.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CircleAvatar(
                          backgroundColor: PulseColors.getCard(_isDarkMode),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: PulseColors.getTextPrimary(_isDarkMode),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile photo upload feature'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: PulseColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.8),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // User Full Name & Handle/Email
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PulseColors.getTextSecondary(_isDarkMode),
                  ),
                ),
                const SizedBox(height: 16),

                // Athlete Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatPill(
                      Icons.emoji_events_rounded,
                      ratingText,
                      PulseColors.accent,
                    ),
                    _buildStatPill(
                      Icons.bolt_rounded,
                      recordText,
                      const Color(0xFF4CAF50),
                    ),
                    _buildStatPill(
                      Icons.sports_tennis_rounded,
                      sportText,
                      const Color(0xFFFF9800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Settings & Security Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account & Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PulseColors.getTextPrimary(_isDarkMode),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Password Setup Tile (Interactive Modal Launcher)
          _buildDrawerMenuItem(
            icon: Icons.lock_reset_rounded,
            title: 'Password & Security Setup',
            subtitle: 'Setup or update account password',
            onTap: () => _showPasswordSetupModal(context),
          ),

          // 4. Other Settings Menu Items
          _buildDrawerMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile Information',
            subtitle: 'Name, bio & preferred court',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Profile Editor')),
              );
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.sports_tennis_rounded,
            title: 'Sport Preferences',
            subtitle: 'Pickleball & Tennis match rules',
            onTap: () {},
          ),
          _buildDrawerMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications & Alerts',
            subtitle: 'Match invites & rating updates',
            onTap: () {},
          ),

          // 5. Dark Mode Theme Setting
          Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PulseColors.getBorder(_isDarkMode),
                width: 1.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PulseColors.getBackground(_isDarkMode),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDarkMode
                        ? Icons.nights_stay_rounded
                        : Icons.wb_sunny_outlined,
                    size: 20,
                    color: _isDarkMode
                        ? PulseColors.secondary
                        : PulseColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode Theme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                      ),
                      Text(
                        _isDarkMode
                            ? 'Dark theme active'
                            : 'Light theme active',
                        style: TextStyle(
                          fontSize: 11,
                          color: PulseColors.getTextSecondary(_isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  activeTrackColor: PulseColors.accent,
                  onChanged: (val) {
                    themeModeNotifier.value = val
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Custom Court Line Graphic Painter for Pulse Hero Section
class CourtLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PulseColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(24, 24, size.width - 48, size.height - 48),
      const Radius.circular(16),
    );
    canvas.drawRRect(centerRect, paint);

    // Center Net Line
    canvas.drawLine(
      Offset(size.width / 2, 24),
      Offset(size.width / 2, size.height - 24),
      paint..strokeWidth = 1.0,
    );

    // Horizontal Service Division Line
    canvas.drawLine(
      Offset(24, size.height / 2),
      Offset(size.width - 24, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Background Court Lines Painter for Full Home Screen Main Content
class MainContentCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PulseColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final marginHorizontal = 16.0;
    final marginTop = 24.0;
    final marginBottom = 40.0;

    final rect = Rect.fromLTRB(
      marginHorizontal,
      marginTop,
      size.width - marginHorizontal,
      size.height - marginBottom,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    canvas.drawRRect(rrect, paint);

    // Center Net Line (Horizontal)
    final centerY = rect.top + (rect.height * 0.44);
    canvas.drawLine(
      Offset(rect.left, centerY),
      Offset(rect.right, centerY),
      paint..strokeWidth = 1.5,
    );

    // Longitude Center Service Divider (Vertical)
    canvas.drawLine(
      Offset(size.width / 2, rect.top),
      Offset(size.width / 2, rect.bottom),
      paint..strokeWidth = 1.0,
    );

    // Non-Volley Zone / Kitchen Line Boundaries
    final serviceTopY = rect.top + (rect.height * 0.22);
    final serviceBottomY = rect.top + (rect.height * 0.66);

    canvas.drawLine(
      Offset(rect.left, serviceTopY),
      Offset(rect.right, serviceTopY),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, serviceBottomY),
      Offset(rect.right, serviceBottomY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
