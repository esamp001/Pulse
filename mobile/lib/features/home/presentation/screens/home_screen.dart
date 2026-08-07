import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';


import '../../../../core/widgets/pulse_bottom_nav_bar.dart';
import '../../../../core/widgets/pulse_widget_card.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';

import '../../../auth/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../matches/models/match_model.dart';
import '../../../matches/presentation/screens/create_match_screen.dart';
import '../../../matches/presentation/screens/match_lobby_screen.dart';
import '../../../matches/presentation/widgets/match_invitation_snackbar.dart';
import '../../../matches/presentation/screens/post_match_screen.dart';
import '../../../notifications/presentation/widgets/notification_side_drawer.dart';
import '../../../notifications/services/notification_service.dart';
import '../../../matches/services/match_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../help/presentation/screens/help_rules_screen.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../rankings/presentation/screens/rankings_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentBottomNavIndex = 0;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;



  UserModel? _user;
  late String _selectedSport;
  bool _isLoadingUser = false;
  MatchModel? _activeMatch;
  StreamSubscription<Map<String, dynamic>>? _activeMatchSubscription;
  String? _dismissedInvitationMatchId;
  List<MatchModel> _historyMatches = [];
  bool _isLoadingHistory = false;
  String _historySportFilter = 'ALL';
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = widget.user ?? AuthService.currentUser;
    _selectedSport = _user?.primarySport ?? 'pickleball';

    if (_user == null && AuthService.currentToken != null) {
      _loadCurrentUserProfile();
    }
    _fetchActiveMatch();
    _fetchMatchHistory();
    _setupRealtimeActiveMatchListener();
    _loadInitialNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchActiveMatch();
    }
  }

  void _setupRealtimeActiveMatchListener() {
    final userId = _user?.id ?? AuthService.currentUser?.id;
    if (userId != null) {
      SocketService().joinUserRoom(userId);
    }

    _activeMatchSubscription?.cancel();
    _activeMatchSubscription = SocketService().onActiveMatchUpdated.listen((_) {
      if (mounted) {
        _fetchActiveMatch();
      }
    });
  }

  Future<void> _loadInitialNotifications() async {
    await NotificationService().fetchBackendNotifications(
      user: _user,
      historyMatches: _historyMatches,
    );
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasUnreadNotifications {
    final unreadList = NotificationService().getNotifications(unreadOnly: true);
    return unreadList.isNotEmpty || _isInvitationPending;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeMatchSubscription?.cancel();
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
        PulseToast.show(context, 'Match invitation declined.');
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
          if (!_user!.configuredSports.map((s) => s.toLowerCase()).contains(_selectedSport.toLowerCase())) {
            _selectedSport = _user!.primarySport;
          }
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

      if (['FINISHED', 'CONFIRMED'].contains(activeMatch.status)) {
        final userId = _user?.id ?? widget.user?.id ?? AuthService.currentToken ?? '';
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostMatchScreen(
              match: activeMatch,
              currentUserId: userId,
            ),
          ),
        );
        _fetchActiveMatch();
        return;
      }

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
                Expanded(
                  child: Text(
                    'Active Room Exists',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      final result = await navigator.push(
                        MaterialPageRoute(
                          builder: (context) => const CreateMatchScreen(),
                        ),
                      );
                      if (result == true || result == 'cancelled') {
                        if (mounted) setState(() => _activeMatch = null);
                      }
                      _fetchActiveMatch();
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
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchLobbyScreen(match: activeMatch),
                    ),
                  );
                  if (result == true || result == 'cancelled') {
                    if (mounted) setState(() => _activeMatch = null);
                  }
                  _fetchActiveMatch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Return to Room'),
              ),
            ],
          );
        },
      );
    } else {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateMatchScreen(),
        ),
      );
      if (result == true || result == 'cancelled') {
        if (mounted) setState(() => _activeMatch = null);
      }
      _fetchActiveMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.firstName ?? 'Elle';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        final isDark = themeMode == ThemeMode.dark;
        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          backgroundColor: PulseColors.getBackground(isDark),
          onEndDrawerChanged: (isOpened) {
            if (!isOpened && mounted) {
              setState(() {});
            }
          },
          drawer: _buildAvatarSideModal(context),
          endDrawer: NotificationSideDrawer(
            isDarkMode: isDark,
            user: _user,
            activeMatch: _activeMatch,
            isInvitationPending: _isInvitationPending,
            historyMatches: _historyMatches,
            onAcceptMatchInvitation: _acceptMatchInvitation,
            onDeclineMatchInvitation: _declineMatchInvitation,
          ),
          body: IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              _buildHomeContent(displayName),
              _buildHistoryTab(),
              _buildHomeContent(displayName), // Compete tab focus
              const RankingsScreen(),
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
                  isDarkMode: isDark,
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
      },
    );
  }

  /// Modern Minimalist Bento Grid Home Screen Content
  Widget _buildHomeContent(String firstName) {
    final wins = _user?.wins ?? 0;
    final losses = _user?.losses ?? 0;
    final totalGames = wins + losses;
    final winRateText = totalGames > 0 ? '${((wins / totalGames) * 100).toStringAsFixed(0)}%' : '0%';
    final activeSportKey = _selectedSport.isEmpty
        ? (_user?.primarySport ?? 'pickleball')
        : _selectedSport;
    final rawRating = _user?.getRatingForSport(activeSportKey) ?? 1200;
    final ratingNumber = rawRating.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    final recordText = '${wins}W · ${losses}L';
    final sportText = '${activeSportKey[0].toUpperCase()}${activeSportKey.substring(1)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Modern Borderless Header Row (Avatar + Greeting + Subtitle + Notification Bell)
          SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // User Avatar Button
                      GestureDetector(
                        onTap: _openAvatarSideModal,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: PulseColors.getSurface(_isDarkMode),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: PulseColors.getBorder(_isDarkMode),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: PulseColors.getTextPrimary(_isDarkMode),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Greeting & Subtitle Column
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                      color: PulseColors.getTextPrimary(_isDarkMode),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_isLoadingUser) ...[
                                  const SizedBox(width: 6),
                                  const SizedBox(
                                    height: 12,
                                    width: 12,
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
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Notification Bell Button with Indicator Badge
                GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: PulseColors.getSurface(_isDarkMode),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: PulseColors.getBorder(_isDarkMode),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                          size: 22,
                        ),
                      ),
                      if (_hasUnreadNotifications)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50), // Green dot indicator
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PulseColors.getBackground(_isDarkMode),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Athlete Hero Rating Display (Clean Typography Focus)
          _buildHeroRatingCard(
            ratingNumber: ratingNumber,
            recordText: recordText,
            winRateText: winRateText,
            streakText: '0 WINS',
            lastMatchText: '+15 PTS',
            sportText: sportText,
            onSportTap: _showSportSelectionModal,
          ),
          const SizedBox(height: 20),

          // 3. Dynamic Featured Hero Action Card ("COMPETE NOW" vs "RETURN TO ROOM")
          PulseWidgetCard(
            title: _activeMatch == null
                ? 'Compete Now'
                : (_activeMatch!.status == 'FINISHED' ? 'Verify Match Result' : 'Active Match Lobby'),
            subtitle: _activeMatch == null
                ? 'Create or join a rated match'
                : (_activeMatch!.status == 'FINISHED'
                    ? 'Scorer submitted outcome • Tap to confirm or dispute'
                    : '${_activeMatch!.sportDisplayName} • ${_activeMatch!.status == 'READY' ? 'Ready to play' : 'Waiting for participants'}'),
            pillText: _activeMatch == null
                ? 'RATED'
                : (_activeMatch!.status == 'FINISHED' ? 'VERIFY' : 'LIVE ROOM'),
            onTap: _onCompeteNowPressed,
            isDarkMode: _isDarkMode,
            customContent: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: PulseColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeMatch == null
                                  ? 'START A MATCH'
                                  : (_activeMatch!.status == 'FINISHED' ? 'VERIFY RESULT' : 'RETURN TO ROOM'),
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SizedBox(
                      height: 48,
                      child: Image.asset(
                        'assets/images/find_court.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.bolt_rounded,
                          size: 36,
                          color: PulseColors.accent,
                        ),
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
              // 1. Scan QR (Card 1)
              PulseWidgetCard(
                imagePath: 'assets/images/scan_qr.png',
                title: 'Scan QR',
                subtitle: 'Join Room',
                pillText: 'FAST',
                isDarkMode: _isDarkMode,
                onTap: () {
                  PulseToast.show(context, 'Opening QR Scanner');
                },
              ),
              // 2. Find Courts (Card 2)
              PulseWidgetCard(
                imagePath: 'assets/images/find_court.png',
                title: 'Find Courts',
                subtitle: 'Locate Courts',
                pillText: 'NEARBY',
                isDarkMode: _isDarkMode,
                onTap: () {
                  PulseToast.show(context, 'Locating nearby courts...');
                },
              ),
              // 3. Officiate (Card 3)
              PulseWidgetCard(
                imagePath: 'assets/images/officiate.png',
                title: 'Officiate',
                subtitle: 'Neutral Ref',
                pillText: 'LIVE',
                isDarkMode: _isDarkMode,
                onTap: () {
                  PulseToast.show(context, 'Opening Officiate Mode');
                },
              ),
              // 4. Log Practice (Card 4)
              PulseWidgetCard(
                imagePath: 'assets/images/all_balls.png',
                title: 'Log Practice',
                subtitle: 'Unrated Drills',
                pillText: 'DRILLS',
                isDarkMode: _isDarkMode,
                onTap: () {
                  PulseToast.show(context, 'Logging practice session...');
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
                        PulseToast.show(context, 'Joined open lobby invitation!');
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

  Future<void> _fetchMatchHistory() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);
    try {
      final matches = await _matchService.fetchUserMatches();
      if (mounted) {
        setState(() {
          _historyMatches = matches;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Widget _buildHistoryTab() {
    final currentUserId = _user?.id ?? AuthService.currentUser?.id;
    final playerOnlyMatches = _historyMatches.where((m) {
      if (currentUserId == null) return true;
      return m.player1Id == currentUserId || m.player2Id == currentUserId;
    }).toList();

    final filteredMatches = _historySportFilter == 'ALL'
        ? playerOnlyMatches
        : playerOnlyMatches
            .where((m) => m.sport.toLowerCase() == _historySportFilter.toLowerCase())
            .toList();

    return RefreshIndicator(
      onRefresh: _fetchMatchHistory,
      color: PulseColors.accent,
      backgroundColor: PulseColors.getSurface(_isDarkMode),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Integrated directly onto page background)
            SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATCH HISTORY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: PulseColors.getTextPrimary(_isDarkMode),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your verified match records & score logs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Sport Filter Pills Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildHistoryFilterChip('ALL', 'All Sports'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('PICKLEBALL', 'Pickleball'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('TENNIS', 'Tennis'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('TABLE_TENNIS', 'Table Tennis'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Match List / Loading / Empty State
            if (_isLoadingHistory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: PulseColors.accent),
                ),
              )
            else if (filteredMatches.isEmpty)
              _buildHistoryEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMatches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final match = filteredMatches[index];
                  return _buildHistoryMatchCard(match);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilterChip(String filterKey, String label) {
    final isSelected = _historySportFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _historySportFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary
              : PulseColors.getSurface(_isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : PulseColors.getBorder(_isDarkMode),
            width: 1.2,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isSelected
                ? Colors.white
                : PulseColors.getTextPrimary(_isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PulseColors.getBackground(_isDarkMode),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 26,
              color: PulseColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Verified Matches Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PulseColors.getTextPrimary(_isDarkMode),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Play and complete rated matches to view your score history and ELO logs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onCompeteNowPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'START A MATCH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMatchCard(MatchModel match) {
    final currentUserId = _user?.id ?? AuthService.currentUser?.id;
    final isPlayer1 = currentUserId == match.player1Id;
    final isPlayer2 = currentUserId == match.player2Id;
    final isWinner = match.winnerId == currentUserId;
    final isFinished = match.status == 'FINISHED' || match.status == 'CONFIRMED';
    final scorerName = match.scorer?.name ?? 'Neutral Ref';

    // Always place logged-in user on the Left and Opponent on the Right
    final String leftName;
    final int? leftRating;
    final String? leftAvatar;
    final bool isLeftCurrentUser;

    final String rightName;
    final int? rightRating;
    final String? rightAvatar;
    final bool isRightCurrentUser;

    if (isPlayer2) {
      leftName = match.player2?.name ?? (_user?.name ?? _user?.firstName ?? 'You');
      leftRating = match.player2?.rating ?? _user?.rating;
      leftAvatar = match.player2?.avatarUrl ?? _user?.avatarUrl;
      isLeftCurrentUser = true;

      rightName = match.player1?.name ?? 'Opponent';
      rightRating = match.player1?.rating;
      rightAvatar = match.player1?.avatarUrl;
      isRightCurrentUser = false;
    } else {
      leftName = match.player1?.name ?? (isPlayer1 ? (_user?.name ?? _user?.firstName ?? 'You') : 'Player 1');
      leftRating = match.player1?.rating ?? (isPlayer1 ? _user?.rating : null);
      leftAvatar = match.player1?.avatarUrl ?? (isPlayer1 ? _user?.avatarUrl : null);
      isLeftCurrentUser = isPlayer1;

      rightName = match.player2?.name ?? (isPlayer2 ? (_user?.name ?? _user?.firstName ?? 'You') : (match.player2Id != null ? 'Opponent' : 'Waiting...'));
      rightRating = match.player2?.rating ?? (isPlayer2 ? _user?.rating : null);
      rightAvatar = match.player2?.avatarUrl ?? (isPlayer2 ? _user?.avatarUrl : null);
      isRightCurrentUser = isPlayer2;
    }

    final outcomeText = !isFinished
        ? match.status
        : (match.winnerId != null
            ? (isWinner ? 'VICTORY' : 'DEFEAT')
            : 'COMPLETED');

    final outcomeColor = !isFinished
        ? PulseColors.accent
        : (isWinner ? const Color(0xFF4CAF50) : PulseColors.getTextSecondary(_isDarkMode));

    final outcomeBg = !isFinished
        ? PulseColors.accent.withValues(alpha: 0.12)
        : (isWinner ? const Color(0xFF4CAF50).withValues(alpha: 0.12) : PulseColors.getBackground(_isDarkMode));

    final dateStr = '${match.scheduledAt.month}/${match.scheduledAt.day}/${match.scheduledAt.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Sport Name + Outcome Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.sportDisplayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: PulseColors.getTextSecondary(_isDarkMode),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•  $dateStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: outcomeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    outcomeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: outcomeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Matchup Row (Left = User, Right = Opponent)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Player (User)
              Expanded(
                child: Row(
                  children: [
                    _buildPlayerAvatarWidget(
                      name: leftName,
                      avatarUrl: leftAvatar,
                      isCurrentUser: isLeftCurrentUser,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leftName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isLeftCurrentUser ? FontWeight.w900 : FontWeight.w700,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (leftRating != null)
                            Text(
                              '$leftRating ELO',
                              style: TextStyle(
                                fontSize: 10,
                                color: PulseColors.getTextSecondary(_isDarkMode),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: PulseColors.getTextSecondary(_isDarkMode),
                    ),
                  ),
                ),
              ),

              // Right Player (Opponent)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            rightName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isRightCurrentUser ? FontWeight.w900 : FontWeight.w700,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (rightRating != null)
                            Text(
                              '$rightRating ELO',
                              style: TextStyle(
                                fontSize: 10,
                                color: PulseColors.getTextSecondary(_isDarkMode),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPlayerAvatarWidget(
                      name: rightName,
                      avatarUrl: rightAvatar,
                      isCurrentUser: isRightCurrentUser,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            height: 1,
            color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),

          // Bottom Meta Info (Venue & Referee)
          Row(
            children: [
              Expanded(
                child: Text(
                  match.venueName.isNotEmpty ? match.venueName : 'Verified Court',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.getTextSecondary(_isDarkMode),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified by $scorerName',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.getTextSecondary(_isDarkMode),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatarWidget({
    required String name,
    required String? avatarUrl,
    required bool isCurrentUser,
  }) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrentUser ? PulseColors.primary : PulseColors.getBorder(_isDarkMode),
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(avatarUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';

    return CircleAvatar(
      radius: 16,
      backgroundColor: isCurrentUser
          ? PulseColors.primary
          : PulseColors.getBackground(_isDarkMode),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isCurrentUser ? Colors.white : PulseColors.getTextPrimary(_isDarkMode),
        ),
      ),
    );
  }

  Widget _buildHeroRatingCard({
    required String ratingNumber,
    required String recordText,
    required String winRateText,
    required String streakText,
    required String lastMatchText,
    required String sportText,
    required VoidCallback onSportTap,
  }) {
    final gradientColors = _isDarkMode
        ? const [Color(0xFF1E393F), Color(0xFF122327)]
        : const [Color(0xFF2A525A), Color(0xFF1E3B41)];
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Color(0xFF9DD4DE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Micro Header & Sport Capsule Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'ELO RATING',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onSportTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sportText.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Prominent Hero Rating Number
          Text(
            ratingNumber,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1.5,
              color: primaryTextColor,
            ),
          ),

          const SizedBox(height: 18),

          // Bottom Sub-Stats Row (No icons, clean typography hierarchy)
          Row(
            children: [
              Expanded(child: _buildHeroStatColumn('RECORD', recordText, primaryTextColor, secondaryTextColor)),
              Expanded(child: _buildHeroStatColumn('WIN RATE', winRateText, primaryTextColor, secondaryTextColor)),
              Expanded(child: _buildHeroStatColumn('STREAK', streakText, primaryTextColor, secondaryTextColor)),
              Expanded(child: _buildHeroStatColumn('LAST MATCH', lastMatchText, primaryTextColor, secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatColumn(String label, String value, Color primaryColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showSportSelectionModal() {
    final configuredSports = _user?.configuredSports ?? [
      _selectedSport.isNotEmpty
          ? '${_selectedSport[0].toUpperCase()}${_selectedSport.substring(1)}'
          : 'Pickleball'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: PulseColors.getSurface(_isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT ACTIVE SPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
                    ),
                    Text(
                      '${configuredSports.length} Active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PulseColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...configuredSports.map((sportName) {
                  final key = sportName.toLowerCase();
                  final isSelected = key == _selectedSport.toLowerCase();
                  final ratingVal = _user?.getRatingForSport(key) ?? 1200;
                  final formattedRating = ratingVal.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      );

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Text(
                          sportName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PulseColors.getTextPrimary(_isDarkMode),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: PulseColors.getBackground(_isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PulseColors.getBorder(_isDarkMode),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            '$formattedRating ELO',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: PulseColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: PulseColors.accent)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSport = key;
                      });
                      Navigator.pop(modalContext);
                    },
                  );
                }),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showSportPreferencesModal(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: PulseColors.getCard(_isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PulseColors.getBorder(_isDarkMode),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: PulseColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manage Sports in Settings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: PulseColors.getTextPrimary(_isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSportPreferencesModal(BuildContext context) {
    final availableSports = [
      {'name': 'Pickleball', 'key': 'pickleball'},
      {'name': 'Tennis', 'key': 'tennis'},
      {'name': 'Table Tennis', 'key': 'table_tennis'},
      {'name': 'Badminton', 'key': 'badminton'},
    ];

    final Map<String, int> draftRatings = Map<String, int>.from(
      _user?.sportRatings ?? {(_user?.primarySport ?? 'pickleball').toLowerCase(): _user?.rating ?? 1200},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PulseColors.getSurface(_isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            void showRatingPickerForSport(String sportKey, String sportName) {
              final currentVal = draftRatings[sportKey] ?? 1200;

              showModalBottomSheet(
                context: sheetContext,
                backgroundColor: PulseColors.getSurface(_isDarkMode),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (pickerContext) {
                  final tiers = [
                    {'label': 'Beginner', 'rating': 1000, 'desc': 'New to competitive play'},
                    {'label': 'Intermediate', 'rating': 1200, 'desc': 'Played social / club games'},
                    {'label': 'Advanced', 'rating': 1400, 'desc': 'Experienced tournament player'},
                  ];

                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DECLARE ELO FOR $sportName'.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...tiers.map((tier) {
                            final ratingVal = tier['rating'] as int;
                            final isSel = currentVal == ratingVal;
                            final formattedTierRating = ratingVal.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            );

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${tier['label']} ($formattedTierRating ELO)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: PulseColors.getTextPrimary(_isDarkMode),
                                ),
                              ),
                              subtitle: Text(
                                '${tier['desc']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PulseColors.getTextSecondary(_isDarkMode),
                                ),
                              ),
                              trailing: isSel
                                  ? const Icon(Icons.check_circle_rounded, color: PulseColors.accent)
                                  : Icon(Icons.radio_button_unchecked_rounded, color: PulseColors.getBorder(_isDarkMode)),
                              onTap: () {
                                setModalState(() {
                                  draftRatings[sportKey] = ratingVal;
                                });
                                Navigator.pop(pickerContext);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            final primaryKey = (_user?.primarySport ?? 'pickleball').toLowerCase();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SPORT PREFERENCES & ELOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(modalContext),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Declare your starting ELO rating for the sports you play. Unconfigured sports remain hidden on your home screen.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: availableSports.map((sport) {
                            final key = sport['key'] as String;
                            final name = sport['name'] as String;
                            final isConfigured = draftRatings.containsKey(key);
                            final isPrimary = key == primaryKey;
                            final eloVal = draftRatings[key];
                            final formattedElo = eloVal != null
                                ? eloVal.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )
                                : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isConfigured
                                    ? PulseColors.getCard(_isDarkMode)
                                    : PulseColors.getSurface(_isDarkMode),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isConfigured
                                      ? PulseColors.accent.withValues(alpha: 0.5)
                                      : PulseColors.getBorder(_isDarkMode),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: isConfigured
                                            ? [
                                                PulseColors.accent.withValues(alpha: 0.25),
                                                PulseColors.primary.withValues(alpha: 0.15),
                                              ]
                                            : [
                                                PulseColors.secondary.withValues(alpha: 0.2),
                                                PulseColors.getBackground(_isDarkMode),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: PulseSportIcons.buildWidget(key, size: 32),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: PulseColors.getTextPrimary(_isDarkMode),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPrimary) ...[
                                              const SizedBox(width: 6),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: PulseColors.primary.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'PRIMARY',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: PulseColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isConfigured ? '$formattedElo ELO' : 'Not configured',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isConfigured
                                                ? PulseColors.accent
                                                : PulseColors.getTextSecondary(_isDarkMode),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (isConfigured) ...[
                                    if (!isPrimary)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                        color: PulseColors.error,
                                        onPressed: () {
                                          setModalState(() {
                                            draftRatings.remove(key);
                                          });
                                        },
                                      ),
                                  ] else ...[
                                    TextButton.icon(
                                      onPressed: () {
                                        draftRatings[key] = 1200;
                                        showRatingPickerForSport(key, name);
                                      },
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Add'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: PulseColors.accent,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final nav = Navigator.of(modalContext);
                                try {
                                  final updated = await _authService.updateSportPreferences(draftRatings);
                                  if (mounted && context.mounted) {
                                    setState(() {
                                      _user = updated;
                                      if (!_user!.configuredSports.map((s) => s.toLowerCase()).contains(_selectedSport.toLowerCase())) {
                                        _selectedSport = _user!.primarySport;
                                      }
                                    });
                                    nav.pop();
                                    PulseToast.show(context, 'Sport preferences updated!');
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (mounted && context.mounted) {
                                    PulseToast.show(
                                      context,
                                      e.toString().replaceAll('Exception: ', ''),
                                      isError: true,
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Preferences',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                      onTap: () => _navigateToEditProfile(context, popDrawer: true),
                    ),
                    _buildDrawerMenuItem(
                      icon: Icons.sports_tennis_rounded,
                      title: 'Sport Preferences',
                      subtitle: 'Declare sports & starting ELO ratings',
                      onTap: () {
                        Navigator.pop(context);
                        _showSportPreferencesModal(context);
                      },
                    ),
                    _buildDrawerMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Rules',
                      subtitle: 'Scoring guides & support',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpRulesScreen(
                              isDarkMode: _isDarkMode,
                            ),
                          ),
                        );
                      },
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





  Future<void> _navigateToEditProfile(BuildContext context, {bool popDrawer = false}) async {
    if (popDrawer) {
      Navigator.pop(context);
    }
    final user = _user ?? widget.user;
    if (user == null) return;

    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: user,
          isDarkMode: _isDarkMode,
        ),
      ),
    );

    if (updatedUser != null && mounted) {
      setState(() {
        _user = updatedUser;
      });
    }
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
                                  PulseToast.show(context,
                                      'Please enter your current password',
                                      isError: true);
                                  return;
                                }

                                if (newPass.length < 6) {
                                  PulseToast.show(context,
                                      'Password must be at least 6 characters long',
                                      isError: true);
                                  return;
                                }

                                if (newPass != confirmPass) {
                                  PulseToast.show(context,
                                      'Passwords do not match',
                                      isError: true);
                                  return;
                                }

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

                                  if (mounted && context.mounted) {
                                    setState(() => _user = updatedUser);
                                    navigator.pop();
                                    PulseToast.show(
                                      context,
                                      hasExistingPassword
                                          ? 'Password updated successfully!'
                                          : 'Rally password created! You can now log in with email/password.',
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (mounted && context.mounted) {
                                    PulseToast.show(
                                      context,
                                      e.toString().replaceAll(
                                          'Exception: ', ''),
                                      isError: true,
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

  Widget _buildProfileStatColumn(String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: PulseColors.getTextPrimary(isDark),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: PulseColors.getTextSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final currentUser = _user ?? widget.user;
    final fullName = currentUser?.name ?? 'Ellejun Apresto Sampaga';
    final email = currentUser?.email ?? 'ellejunsampaga@gmail.com';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E';
    final avatarUrl = currentUser?.avatarUrl;
    final coverPhotoUrl = currentUser?.coverPhotoUrl;
    final wins = currentUser?.wins ?? 0;
    final losses = currentUser?.losses ?? 0;
    final totalMatches = wins + losses;
    final winRate = totalMatches > 0 ? '${((wins / totalMatches) * 100).round()}%' : '0%';
    final rating = currentUser?.rating ?? 1200;
    final primarySport = (currentUser?.primarySport ?? 'pickleball').toUpperCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Full-Width Edge-to-Edge Banner & 50/50 Overlapping Avatar (100% Screen Width)
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Full-Width Cover Photo Banner Header
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isDarkMode ? PulseColors.darkCard : PulseColors.secondary.withValues(alpha: 0.3),
                  gradient: (coverPhotoUrl == null || coverPhotoUrl.isEmpty)
                      ? LinearGradient(
                          colors: _isDarkMode
                              ? [const Color(0xFF1B3B36), const Color(0xFF0F2622)]
                              : [PulseColors.primary, const Color(0xFF2C5E55)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverPhotoUrl != null && coverPhotoUrl.isNotEmpty)
                      Image.network(
                        coverPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Center(
                          child: Icon(
                            Icons.sports_tennis_rounded,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(
                          Icons.sports_tennis_rounded,
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                  ],
                ),
              ),

              // Overlapping Avatar (50% on top banner, 50% on bottom content)
              Positioned(
                top: 92, // 140 - (96 / 2) = 92px. Exactly 50% top, 50% bottom!
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PulseColors.getBackground(_isDarkMode),
                            border: Border.all(
                              color: PulseColors.getBackground(_isDarkMode),
                              width: 3.5,
                            ),
                          ),
                          child: ClipOval(
                            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          color: PulseColors.getTextPrimary(_isDarkMode),
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
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
                            onTap: () => _navigateToEditProfile(context, popDrawer: false),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: PulseColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 54),

          // Streak / Rating Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: PulseColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFFFF4500), // Fiery red-orange
                ),
                const SizedBox(width: 4),
                Text(
                  '$rating ELO',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Rest of Profile Content uses Horizontal Padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // User Full Name (Bold Uppercase)
                Text(
                  fullName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
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

                // Phone & Location Text Row
                if ((currentUser?.phoneNumber?.isNotEmpty ?? false) ||
                    (currentUser?.location?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentUser?.phoneNumber?.isNotEmpty ?? false) ...[
                        Icon(
                          Icons.phone_rounded,
                          size: 13,
                          color: PulseColors.getTextSecondary(_isDarkMode),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentUser!.phoneNumber!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                        ),
                      ],
                      if ((currentUser?.phoneNumber?.isNotEmpty ?? false) &&
                          (currentUser?.location?.isNotEmpty ?? false)) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                          ),
                        ),
                      ],
                      if (currentUser?.location?.isNotEmpty ?? false) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: PulseColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            currentUser!.location!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Player Bio / Tagline
                if (currentUser?.bio?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentUser!.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: PulseColors.getTextPrimary(_isDarkMode).withValues(alpha: 0.85),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Sport Pill Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: PulseColors.getSurface(_isDarkMode),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PulseColors.getBorder(_isDarkMode),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sports_tennis_rounded, size: 15, color: PulseColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            primarySport,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats Overview Row (3 Columns: Wins, Matches, Win Rate)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: PulseColors.getSurface(_isDarkMode),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: PulseColors.getBorder(_isDarkMode),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStatColumn('$wins', 'Wins', _isDarkMode),
                      Container(
                        width: 1,
                        height: 32,
                        color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.5),
                      ),
                      _buildProfileStatColumn('$totalMatches', 'Matches', _isDarkMode),
                      Container(
                        width: 1,
                        height: 32,
                        color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.5),
                      ),
                      _buildProfileStatColumn(winRate, 'Win rates', _isDarkMode),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          // 2. Account & Settings Section with 20px Horizontal Padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account & Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Password Setup Tile
                _buildDrawerMenuItem(
                  icon: Icons.lock_reset_rounded,
                  title: 'Password & Security Setup',
                  subtitle: 'Setup or update account password',
                  onTap: () => _showPasswordSetupModal(context),
                ),

                // Other Settings Menu Items
                _buildDrawerMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile Information',
                  subtitle: 'Update details & photo',
                  onTap: () => _navigateToEditProfile(context),
                ),
                _buildDrawerMenuItem(
                  icon: Icons.sports_tennis_rounded,
                  title: 'Sport Preferences',
                  subtitle: 'Declare sports & starting ELO ratings',
                  onTap: () {
                    _showSportPreferencesModal(context);
                  },
                ),

                // Dark Mode Theme Setting
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
                const SizedBox(height: 110),

              ],
            ),
          ),
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
