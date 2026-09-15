import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../../auth/services/auth_service.dart';
import '../../../courts/models/court_model.dart';
import '../../../courts/presentation/widgets/court_picker_modal.dart';
import '../../../courts/presentation/widgets/suggest_court_modal.dart';
import '../../services/match_service.dart';
import '../widgets/sport_selector_card.dart';
import 'match_lobby_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  final String? initialVenueName;
  final String? initialSport;
  final String? initialLocation;
  final CourtModel? initialCourt;

  const CreateMatchScreen({
    super.key,
    this.initialVenueName,
    this.initialSport,
    this.initialLocation,
    this.initialCourt,
  });

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchService _matchService = MatchService();

  // Step 0: Sport & Mode Selection, Step 1: Mode Walkthrough & Configuration
  int _currentStep = 0;

  String _selectedSport = 'pickleball';
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  CourtModel? _selectedCourt;
  bool _isManualVenueEntry = false;

  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  int _totalSets = 3;
  int _pointsToWinSet = 11;
  bool _winByTwo = true;
  String _matchType = 'singles';

  bool _isSubmitting = false;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Color get _accentColor => _isDarkMode ? PulseColors.secondary : PulseColors.accent;

  static final List<SportOption> _sports = [
    SportOption(
      key: 'pickleball',
      title: 'Pickleball',
      subtitle: 'Fast-paced paddle sport on a court',
      icon: PulseSportIcons.pickleball,
      imageAsset: 'assets/images/PICKLE-BALL-ASSET.png',
    ),
    SportOption(
      key: 'tennis',
      title: 'Tennis',
      subtitle: 'Classic racket sport, sets & games',
      icon: PulseSportIcons.tennis,
      imageAsset: 'assets/images/TENNIS-ASSET.png',
    ),
    SportOption(
      key: 'badminton',
      title: 'Badminton',
      subtitle: 'High-speed shuttlecock racket game',
      icon: PulseSportIcons.badminton,
      imageAsset: 'assets/images/BADMINTON-ASSET.png',
    ),
    SportOption(
      key: 'table_tennis',
      title: 'Table Tennis',
      subtitle: 'Ping pong indoor table competition',
      icon: PulseSportIcons.tableTennis,
      imageAsset: 'assets/images/TABLE-TENNIS-ASSET.png',
    ),
  ];

  List<SportOption> get _availableSports {
    final user = AuthService.currentUser;

    if (user == null) return _sports;

    final configuredNorm = <String>{};

    for (final s in user.configuredSports) {
      configuredNorm.add(s.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim());
    }

    for (final k in user.sportRatings.keys) {
      configuredNorm.add(k.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim());
    }

    if (user.primarySport.isNotEmpty) {
      configuredNorm.add(user.primarySport.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim());
    }

    if (configuredNorm.isEmpty) return _sports;

    final filtered = _sports.where((s) {
      final normKey = s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      return configuredNorm.contains(normKey);
    }).toList();

    if (widget.initialSport != null && widget.initialSport!.isNotEmpty) {
      final initialNorm = widget.initialSport!.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final matchInitial = _sports.where((s) => s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim() == initialNorm);
      for (final s in matchInitial) {
        if (!filtered.any((f) => f.key == s.key)) {
          filtered.add(s);
        }
      }
    }

    return filtered.isNotEmpty ? filtered : _sports;
  }

  String _getSportAsset(String key) {
    switch (key.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim()) {
      case 'pickleball':
        return 'assets/images/PICKLE-BALL-ASSET.png';
      case 'tennis':
        return 'assets/images/TENNIS-ASSET.png';
      case 'badminton':
        return 'assets/images/BADMINTON-ASSET.png';
      case 'table_tennis':
      case 'tabletennis':
      case 'ping_pong':
        return 'assets/images/TABLE-TENNIS-ASSET.png';
      default:
        return 'assets/images/PICKLE-BALL-ASSET.png';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCourt != null) {
      _selectedCourt = widget.initialCourt;
      _venueNameController.text = widget.initialCourt!.name;
      _locationController.text = widget.initialCourt!.address ?? widget.initialCourt!.city ?? '';
    } else {
      if (widget.initialVenueName != null && widget.initialVenueName!.isNotEmpty) {
        _venueNameController.text = widget.initialVenueName!;
      }
      if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
        _locationController.text = widget.initialLocation!;
      }
    }
    final available = _availableSports;
    if (widget.initialSport != null && widget.initialSport!.isNotEmpty) {
      final norm = widget.initialSport!.toLowerCase().replaceAll(' ', '_');
      if (available.any((s) => s.key == norm)) {
        _selectedSport = norm;
        return;
      }
    }
    final user = AuthService.currentUser;
    if (user != null && user.primarySport.isNotEmpty) {
      final primaryNorm = user.primarySport.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final matched = available.firstWhere(
        (s) => s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim() == primaryNorm,
        orElse: () => available.first,
      );
      _selectedSport = matched.key;
    } else if (available.isNotEmpty) {
      _selectedSport = available.first.key;
    }
  }

  @override
  void dispose() {
    _venueNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PulseColors.primary,
              onPrimary: Colors.white,
              surface: PulseColors.getSurface(_isDarkMode),
              onSurface: PulseColors.getTextPrimary(_isDarkMode),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onCourtSelected(CourtModel court) {
    setState(() {
      _selectedCourt = court;
      _venueNameController.text = court.name;
      _locationController.text = court.address ?? court.city ?? '';
      _isManualVenueEntry = false;
    });
  }

  void _openCourtPicker() {
    CourtPickerModal.show(
      context,
      isDarkMode: _isDarkMode,
      initialSport: _selectedSport,
      onCourtSelected: _onCourtSelected,
    );
  }

  void _openSuggestCourtModal() {
    SuggestCourtModal.show(
      context,
      isDarkMode: _isDarkMode,
      onCourtCreated: (newCourt) {
        _onCourtSelected(newCourt);
        PulseToast.show(context, 'Court registered and selected!');
      },
    );
  }

  Future<void> _handleCreateMatch() async {
    if (_venueNameController.text.trim().isEmpty) {
      PulseToast.show(context, 'Please select or enter a venue', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final createdMatch = await _matchService.createMatch(
        sport: _selectedSport,
        venueName: _venueNameController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        scheduledAt: scheduledDateTime,
        matchType: _matchType,
        totalSets: _totalSets,
        pointsToWinSet: _pointsToWinSet,
        winByTwo: _winByTwo,
      );

      if (mounted) {
        PulseToast.show(context, 'Match created! Entering lobby...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MatchLobbyScreen(match: createdMatch),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        PulseToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatTimeText() {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: PulseColors.getTextSecondary(_isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? _accentColor
                    : PulseColors.getTextPrimary(_isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.15)
              : PulseColors.getCard(_isDarkMode),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (_isDarkMode ? Colors.white : PulseColors.primary)
                : PulseColors.getTextPrimary(_isDarkMode),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 0: SPORT & GAME MODE SELECTION
  // ==========================================

  Widget _buildStep0SportAndMode() {
    final textPrimary = PulseColors.getTextPrimary(_isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(_isDarkMode);
    final cardBg = PulseColors.getCard(_isDarkMode);
    final isDoubles = _matchType == 'doubles';

    final headerBg = _isDarkMode ? const Color(0xFF0C191B) : const Color(0xFF14373E);
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Merged Header: Navigation row + "What do you want to play?" + Sport Asset
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 18),
          decoration: BoxDecoration(
            color: headerBg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Row
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    PulseBackButton(
                      isDarkMode: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Create Match',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAY TOGETHER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            text: 'What do you\nwant to ',
                            style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: 'play?',
                                style: TextStyle(color: _accentColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pick a sport and get on the court.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dynamic Sport Asset Illustration
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentColor.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      _getSportAsset(_selectedSport),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.sports_tennis_rounded,
                        size: 40,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Remaining Step 0 content with 16dp horizontal padding
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select a sport section (4 Cards in a horizontal row)
              Text(
                'Select a sport',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        if (_availableSports.length == 1)
          Row(
            children: [
              SizedBox(
                width: 100,
                child: _buildSportCardItem(
                  sport: _availableSports.first,
                  isSelected: true,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          )
        else
          Row(
            children: _availableSports.map((sport) {
              final isSelected = _selectedSport == sport.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildSportCardItem(
                    sport: sport,
                    isSelected: isSelected,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 24),

        // 3. Choose game mode section (Singles vs Doubles)
        Text(
          'Choose game mode',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Singles Card
        _buildGameModeCardItem(
          modeKey: 'singles',
          isSelected: !isDoubles,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 12),

        // Doubles Card
        _buildGameModeCardItem(
          modeKey: 'doubles',
          isSelected: isDoubles,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    ),
  ),
],
);
}

  Widget _buildSportCardItem({
    required SportOption sport,
    required bool isSelected,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSport = sport.key;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 108,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.35),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Image.asset(
                      sport.imageAsset ?? _getSportAsset(sport.key),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text(
                        sport.title,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? textPrimary : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeCardItem({
    required String modeKey,
    required bool isSelected,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDoubles = modeKey == 'doubles';
    final assetPath = isDoubles
        ? 'assets/images/DOUBLES-ASSET.png'
        : 'assets/images/SINGLE-ASSET.png';

    return InkWell(
      onTap: () => setState(() => _matchType = modeKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 100,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.35),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final assetWidth = (maxW * 0.40).clamp(96.0, 148.0);
            const slantWidth = 20.0;

            return Row(
              children: [
                // Left: Slanted Asset Illustration with padding inside container
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ClipPath(
                    clipper: const _SlantedAssetClipper(
                      slant: slantWidth,
                      cornerRadius: 6,
                      leftRadius: 10,
                    ),
                    child: Container(
                      width: assetWidth,
                      height: double.infinity,
                      color: _isDarkMode ? PulseColors.darkSurface : PulseColors.background,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        alignment: isDoubles ? Alignment.center : Alignment.centerLeft,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            isDoubles ? Icons.group : Icons.person,
                            color: _accentColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Center: Mode Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isDoubles ? 'Doubles' : 'Singles',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isDoubles ? '2 vs 2. Play with a friend.' : '1 vs 1. Test your skills.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Right: Chevron
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary.withValues(alpha: 0.8),
                    size: 24,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: MODE WALKTHROUGH & MATCH CONFIG
  // ==========================================

  Widget _buildStep1ModeWalkthroughAndDetails() {
    final textPrimary = PulseColors.getTextPrimary(_isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(_isDarkMode);
    final cardBg = PulseColors.getCard(_isDarkMode);
    final isDoubles = _matchType == 'doubles';

    final steps = isDoubles
        ? const [
            (Icons.person_add_alt_1_outlined, '1', 'Invite your partner', 'Team up with a friend.'),
            (Icons.group_outlined, '2', 'Find opponents', 'Match with nearby players.'),
            (Icons.sports_tennis_rounded, '3', 'Play the match', 'Enjoy the game and have fun!'),
            (Icons.bar_chart_rounded, '4', 'Track your results', 'Both win or lose Elo points.'),
          ]
        : const [
            (Icons.person_search_outlined, '1', 'Find opponent', 'Match with a rival or invite a friend.'),
            (Icons.sports_tennis_rounded, '2', 'Play the match', 'Enjoy official verified match play!'),
            (Icons.bar_chart_rounded, '3', 'Track your results', 'Win or lose individual Elo points.'),
          ];

    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Merged Header: Navigation row + "Team up and play." + Asset merged throughout
        LayoutBuilder(
          builder: (context, constraints) {
            final bannerWidth = constraints.maxWidth;
            final bannerBg = _isDarkMode ? const Color(0xFF0C191B) : const Color(0xFF14373E);
            final artworkWidth = (bannerWidth * 0.70).clamp(185.0, bannerWidth);
            final textWidth = (bannerWidth * 0.65).clamp(155.0, bannerWidth);
            final headerHeight = 215.0 + topInset;

            return Container(
              width: double.infinity,
              height: headerHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: bannerBg,
              ),
              child: Stack(
                children: [
                  // 1. Full-height athletic hero illustration with Soft Edge ShaderMask (Option B)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: artworkWidth,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.30, 0.96, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        isDoubles
                            ? 'assets/images/TEAM-UP-AND-PLAY-ASSET.png'
                            : 'assets/images/SINGLE-ASSET.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 2. Horizontal gradient scrim for text contrast
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            bannerBg,
                            bannerBg.withValues(alpha: 0.95),
                            bannerBg.withValues(alpha: 0.40),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Merged Top Bar + Hero Content
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(top: topInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. Top Navigation Bar Row (merged directly into the asset header!)
                          SizedBox(
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  PulseBackButton(
                                    isDarkMode: true,
                                    onPressed: () {
                                      setState(() => _currentStep = 0);
                                    },
                                  ),
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        'Create Match',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // B. Hero Content (pill, title, subtitle)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: textWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: _accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _accentColor.withValues(alpha: 0.8), width: 1.2),
                                    ),
                                    child: Text(
                                      isDoubles ? 'DOUBLES' : 'SINGLES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: _accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: RichText(
                                      text: TextSpan(
                                        text: isDoubles ? 'Team up\nand ' : 'Head to head\nand ',
                                        style: GoogleFonts.lexend(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          height: 1.15,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'play.',
                                            style: TextStyle(color: _accentColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isDoubles
                                          ? 'Invite a friend, find opponents,\nand hit the court together.'
                                          : 'Challenge an opponent, assign a scorer,\nand compete for the win.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.25,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // 2. Remaining configuration content with 16dp padding
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. "How it works" timeline card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'How it works',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${steps.length} steps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...List.generate(steps.length, (index) {
                final item = steps[index];
                final isLast = index == steps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Step Number badge + connector line
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.$1, size: 20, color: textSecondary),
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.07),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isLast)
                          Container(
                            margin: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
                            width: 1.5,
                            height: 20,
                            color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.4),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$4,
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Elo Incentive Card ("Play together, climb together")
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDoubles ? 'Play together, climb together' : 'Solo battle, solo glory',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDoubles
                          ? 'Doubles matches also affect your Elo rating.'
                          : 'Singles matches directly determine your official Elo rank.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4. Venue & Location Section
        _buildVenueSection(),

        const SizedBox(height: 24),

        // 5. Schedule Time (Today Only)
        Text(
          'Schedule Time (Today)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Read-Only Date Display (Today)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20, color: _accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: PulseColors.textSecondary),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Time Picker Button
            Expanded(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: _accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Time',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: PulseColors.textSecondary),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatTimeText(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 6. Custom Scoring Rules
        Text(
          'Custom Scoring Rules',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match Format (Total Sets)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOptionChip(
                    label: '1 Set (Single)',
                    isSelected: _totalSets == 1,
                    onTap: () => setState(() => _totalSets = 1),
                  ),
                  _buildOptionChip(
                    label: 'Best of 3 Sets',
                    isSelected: _totalSets == 3,
                    onTap: () => setState(() => _totalSets = 3),
                  ),
                  _buildOptionChip(
                    label: 'Best of 5 Sets',
                    isSelected: _totalSets == 5,
                    onTap: () => setState(() => _totalSets = 5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Points to Win Set',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOptionChip(
                    label: '11 Points',
                    isSelected: _pointsToWinSet == 11,
                    onTap: () => setState(() => _pointsToWinSet = 11),
                  ),
                  _buildOptionChip(
                    label: '15 Points',
                    isSelected: _pointsToWinSet == 15,
                    onTap: () => setState(() => _pointsToWinSet = 15),
                  ),
                  _buildOptionChip(
                    label: '21 Points',
                    isSelected: _pointsToWinSet == 21,
                    onTap: () => setState(() => _pointsToWinSet = 21),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Win by 2 Points',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Must lead by at least 2 points to win set',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _winByTwo,
                    activeThumbColor: PulseColors.primary,
                    activeTrackColor: PulseColors.primary.withValues(alpha: 0.35),
                    onChanged: (val) => setState(() => _winByTwo = val),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 7. Match Setup Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Match Setup Summary',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Sport',
                _sports.firstWhere((s) => s.key == _selectedSport).title,
              ),
              _buildSummaryRow(
                'Venue',
                _venueNameController.text.trim().isEmpty
                    ? 'Not specified'
                    : _venueNameController.text.trim(),
              ),
              _buildSummaryRow(
                'Format',
                '${_matchType == "doubles" ? "Doubles (2v2) • " : "Singles (1v1) • "}${_totalSets == 1 ? "1 Set" : "Best of $_totalSets Sets"} ($_pointsToWinSet pts${_winByTwo ? ", win by 2" : ""})',
              ),
              _buildSummaryRow(
                'Start Time',
                'Today at ${_formatTimeText()}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 4),
              _buildSummaryRow(
                'Next Step',
                _matchType == 'doubles'
                    ? 'Invite Teammate, Opponents & Scorer'
                    : 'Invite Player 2 & Assign Scorer',
                isHighlight: true,
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VENUE PICKER & DISPLAY SECTIONS
  // ==========================================

  Widget _buildVenueSection() {
    final isDark = _isDarkMode;
    final cardColor = PulseColors.getCard(isDark);
    final textPrimary = PulseColors.getTextPrimary(isDark);
    final textSecondary = PulseColors.getTextSecondary(isDark);

    final hasVenue = _venueNameController.text.trim().isNotEmpty;

    if (_isManualVenueEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Venue & Location',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _isManualVenueEntry = false);
                  _openCourtPicker();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Find Court',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _venueNameController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Venue Name *',
              labelStyle: TextStyle(color: textSecondary),
              hintText: 'e.g. Metro Sports Club Court 3',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              fillColor: cardColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a venue name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Address or Directions (Optional)',
              labelStyle: TextStyle(color: textSecondary),
              hintText: 'e.g. 123 Main St, Downtown',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              fillColor: cardColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (hasVenue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Venue & Location',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openCourtPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Change Court',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectedVenueBanner(isDark),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _venueNameController.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      if (_locationController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _locationController.text.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          InkWell(
                            onTap: _openCourtPicker,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 15,
                                    color: _accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Change Court',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCourt = null;
                                _venueNameController.clear();
                                _locationController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: PulseColors.error,
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
          ),
        ],
      );
    }

    // Default Unselected State
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue & Location',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _openCourtPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Choose a court...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: PulseColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Browse',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Can\'t find your court?',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            InkWell(
              onTap: _openSuggestCourtModal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Suggest Court',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _isManualVenueEntry = true);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Enter Manually',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedVenueBanner(bool isDark) {
    final court = _selectedCourt;
    final hasNetworkImage = court != null &&
        court.imageUrl != null &&
        court.imageUrl!.trim().isNotEmpty;
    final sportKey = court?.primarySport.toLowerCase() ?? _selectedSport;
    final primarySportName = court?.primarySport ??
        _sports.firstWhere((s) => s.key == sportKey, orElse: () => _sports.first).title;

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasNetworkImage)
            Image.network(
              court.imageUrl!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildSportFallbackBanner(isDark, sportKey),
            )
          else
            _buildSportFallbackBanner(isDark, sportKey),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                primarySportName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (court != null && court.formattedDistance.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 10,
                      color: _accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      court.formattedDistance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSportFallbackBanner(bool isDark, String sportKey) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF14373E), const Color(0xFF0C2227)]
              : [const Color(0xFFD3EAEF), const Color(0xFFB5DDE4)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtGridLinePainter(
                lineColor: (isDark ? Colors.white : PulseColors.primary)
                    .withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -14,
            child: Opacity(
              opacity: isDark ? 0.16 : 0.22,
              child: PulseSportIcons.buildWidget(
                sportKey,
                size: 95,
                color: isDark ? Colors.white : PulseColors.primary,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableSports;
    if (!available.any((s) => s.key == _selectedSport) && available.isNotEmpty) {
      _selectedSport = available.first.key;
    }

    final isDoubles = _matchType == 'doubles';

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          setState(() => _currentStep = 0);
        }
      },
      child: Scaffold(
        backgroundColor: PulseColors.getBackground(_isDarkMode),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Form(
                    key: _formKey,
                    child: _currentStep == 0
                        ? _buildStep0SportAndMode()
                        : _buildStep1ModeWalkthroughAndDetails(),
                  ),
                ),
              ),

              // Bottom Sticky Action Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: PulseColors.getBackground(_isDarkMode),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentStep == 0) {
                              setState(() => _currentStep = 1);
                            } else {
                              _handleCreateMatch();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentStep == 0
                                      ? 'Continue'
                                      : (isDoubles
                                          ? 'Create Doubles Match'
                                          : 'Create Singles Match'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtGridLinePainter extends CustomPainter {
  final Color lineColor;

  const _CourtGridLinePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final courtRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(6),
    );
    canvas.drawRRect(courtRect, paint);

    canvas.drawLine(
      Offset(size.width / 2, 8),
      Offset(size.width / 2, size.height - 8),
      paint,
    );

    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtGridLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _SlantedAssetClipper extends CustomClipper<Path> {
  final double slant;
  final double cornerRadius;
  final double leftRadius;

  const _SlantedAssetClipper({
    this.slant = 20.0,
    this.cornerRadius = 6.0,
    this.leftRadius = 10.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(leftRadius, 0);

    final topSlantX = size.width - slant;
    path.lineTo(topSlantX - cornerRadius, 0);
    path.quadraticBezierTo(
      topSlantX,
      0,
      topSlantX + (slant * (cornerRadius / size.height)),
      cornerRadius,
    );

    path.lineTo(
      size.width - (slant * (cornerRadius / size.height)),
      size.height - cornerRadius,
    );
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    path.lineTo(leftRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - leftRadius);

    path.lineTo(0, leftRadius);
    path.quadraticBezierTo(0, 0, leftRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SlantedAssetClipper oldClipper) =>
      oldClipper.slant != slant ||
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.leftRadius != leftRadius;
}

