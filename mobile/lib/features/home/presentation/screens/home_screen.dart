import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_top_bar.dart';
import '../../../../core/widgets/pulse_bottom_nav_bar.dart';
import '../../../../main.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;

  const HomeScreen({
    super.key,
    this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  int _selectedCategoryIndex = 0; // 0: Start Match, 1: Officiate, 2: Leaderboard
  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  UserModel? _user;
  bool _isLoadingUser = false;
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? AuthService.currentUser;

    if (_user == null && AuthService.currentToken != null) {
      _loadCurrentUserProfile();
    }
  }

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

  void _onCompeteNowPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting match creation wizard...'),
        backgroundColor: PulseColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
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
      bottomNavigationBar: PulseBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  /// Nike Run Club Inspired Home Screen Content
  Widget _buildHomeContent(String firstName) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Personalized Greeting Header
          Row(
            children: [
              Text(
                'Welcome Back, $firstName!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                  letterSpacing: -0.6,
                ),
              ),
              if (_isLoadingUser) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: PulseColors.accent),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 2. Horizontal Sub-Tabs ("Start a Match", "Officiate", "Training Plans")
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTab(0, 'Start a Match'),
                const SizedBox(width: 20),
                _buildSubTab(1, 'Officiate'),
                const SizedBox(width: 20),
                _buildSubTab(2, 'Leaderboard'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Featured Horizontal Image Card (Flat Minimalist Overlay)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PulseColors.getBorder(_isDarkMode), width: 1.0),
            ),
            child: Row(
              children: [
                // Pulse Sports Banner Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/pulse_sports_banner.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 76,
                        height: 76,
                        color: PulseColors.primary,
                        child: const Icon(Icons.sports_tennis, color: Colors.white, size: 32),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official Scored • 8 Weeks Left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: PulseColors.getTextSecondary(_isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '10K Ranking Ladder',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pagination Dots (Nike Style `■ — — —`)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: PulseColors.getTextPrimary(_isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: PulseColors.getBorder(_isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: PulseColors.getBorder(_isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: PulseColors.getBorder(_isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 4. Central Hero Section: Vector Tennis Court Lines + Big Circular COMPETE Button
          Center(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 230,
                  decoration: BoxDecoration(
                    color: PulseColors.getBackground(_isDarkMode),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vector Tennis Court Lines Background
                      CustomPaint(
                        size: const Size(double.infinity, 230),
                        painter: CourtLinePainter(),
                      ),

                      // Side Options & Big Central COMPETE Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left Option Button: Match Specs
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening Match Rules & Settings')),
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: PulseColors.getSurface(_isDarkMode),
                                shape: BoxShape.circle,
                                border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                color: PulseColors.getTextPrimary(_isDarkMode),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Central Circular "COMPETE NOW" Button
                          GestureDetector(
                            onTap: _onCompeteNowPressed,
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                color: _isDarkMode ? PulseColors.accent : PulseColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'COMPETE\nNOW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right Option Button: Officiate / QR Scanner
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Scanner / Officiate Mode')),
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: PulseColors.getSurface(_isDarkMode),
                                shape: BoxShape.circle,
                                border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
                              ),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: PulseColors.getTextPrimary(_isDarkMode),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom Pill Button ("Quick Match Setup")
                ElevatedButton(
                  onPressed: _onCompeteNowPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.getSurface(_isDarkMode),
                    foregroundColor: PulseColors.getTextPrimary(_isDarkMode),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text(
                    'Quick Match Setup',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? PulseColors.getTextPrimary(_isDarkMode)
                  : (_isDarkMode ? PulseColors.darkTextSecondary : PulseColors.textDisabled),
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2,
              width: 24,
              color: PulseColors.getTextPrimary(_isDarkMode),
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
          Icon(Icons.construction_rounded, size: 48, color: PulseColors.accent.withValues(alpha: 0.7)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    icon: Icon(Icons.close_rounded, color: PulseColors.getTextPrimary(_isDarkMode), size: 22),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: PulseColors.getBackground(_isDarkMode),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
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
                              border: Border.all(color: PulseColors.getBorder(_isDarkMode), width: 1.0),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: PulseColors.getTextPrimary(_isDarkMode),
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
                                    color: PulseColors.getTextPrimary(_isDarkMode),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11,
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
                    const SizedBox(height: 16),

                    // Athlete Quick Stats
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: PulseColors.getSurface(_isDarkMode),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDrawerStatItem('ELO', _user != null ? '${_user!.rating}' : '1,200'),
                          Container(width: 1, height: 24, color: PulseColors.getBorder(_isDarkMode)),
                          _buildDrawerStatItem('RECORD', _user != null ? '${_user!.wins}W-${_user!.losses}L' : '0W-0L'),
                          Container(width: 1, height: 28, color: PulseColors.getBorder(_isDarkMode)),
                          _buildDrawerStatItem('WIN RATE', '100%'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dark Mode Toggle Switch (Standard Side Drawer Setting)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PulseColors.getSurface(_isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
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
                              _isDarkMode ? Icons.nights_stay_rounded : Icons.wb_sunny_outlined,
                              size: 18,
                              color: _isDarkMode ? PulseColors.secondary : PulseColors.primary,
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
                                    color: PulseColors.getTextPrimary(_isDarkMode),
                                  ),
                                ),
                                Text(
                                  _isDarkMode ? 'Dark theme active' : 'Light theme active',
                                  style: TextStyle(
                                    fontSize: 10,
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
                              themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
                  color: _isDarkMode ? PulseColors.secondary : PulseColors.primary,
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
              const Icon(Icons.chevron_right_rounded, color: PulseColors.border, size: 20),
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 5),
        backgroundColor: PulseColors.getSurface(_isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: PulseColors.getBorder(_isDarkMode), width: 1.0),
        ),
        elevation: 6,
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
                    'Log out of Pulse?',
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
          onPressed: () {
            AuthService.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final fullName = _user?.name ?? 'Ellejun Apresto Sampaga';
    final email = _user?.email ?? 'ellejunsampaga@gmail.com';
    final initials = _user?.firstName != null && _user!.firstName.isNotEmpty
        ? _user!.firstName[0].toUpperCase()
        : 'E';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Profile Header Card (Horizontal Pill Layout)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: PulseColors.getBackground(_isDarkMode),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PulseColors.getSurface(_isDarkMode),
                    shape: BoxShape.circle,
                    border: Border.all(color: PulseColors.getBorder(_isDarkMode), width: 1.0),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: PulseColors.getTextPrimary(_isDarkMode),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
                        fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
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
          const SizedBox(height: 16),

          // Athlete Quick Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDrawerStatItem('ELO', _user != null ? '${_user!.rating}' : '1,200'),
                Container(width: 1, height: 24, color: PulseColors.getBorder(_isDarkMode)),
                _buildDrawerStatItem('RECORD', _user != null ? '${_user!.wins}W-${_user!.losses}L' : '0W-0L'),
                Container(width: 1, height: 28, color: PulseColors.getBorder(_isDarkMode)),
                _buildDrawerStatItem('WIN RATE', '100%'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dark Mode Toggle Switch
          Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PulseColors.getSurface(_isDarkMode),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
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
                    _isDarkMode ? Icons.nights_stay_rounded : Icons.wb_sunny_outlined,
                    size: 18,
                    color: _isDarkMode ? PulseColors.secondary : PulseColors.primary,
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
                          color: PulseColors.getTextPrimary(_isDarkMode),
                        ),
                      ),
                      Text(
                        _isDarkMode ? 'Dark theme active' : 'Light theme active',
                        style: TextStyle(
                          fontSize: 10,
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
                    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
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
          const SizedBox(height: 16),

          // Bottom Modern Log Out Section
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmationDialog(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
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

    canvas.drawLine(Offset(rect.left, serviceTopY), Offset(rect.right, serviceTopY), paint);
    canvas.drawLine(Offset(rect.left, serviceBottomY), Offset(rect.right, serviceBottomY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
