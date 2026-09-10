import 'package:flutter/material.dart';
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

  String _selectedSport = 'pickleball';
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  CourtModel? _selectedCourt;
  bool _isManualVenueEntry = false;

  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  int _totalSets = 3;
  int _pointsToWinSet = 11;
  bool _winByTwo = true;

  bool _isSubmitting = false;
  bool _isSportsExpanded = false;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static final List<SportOption> _sports = [
    SportOption(
      key: 'pickleball',
      title: 'Pickleball',
      subtitle: 'Fast-paced paddle sport on a court',
      icon: PulseSportIcons.pickleball,
      imageAsset: PulseSportIcons.pickleballAsset,
    ),
    SportOption(
      key: 'tennis',
      title: 'Tennis',
      subtitle: 'Classic racket sport, sets & games',
      icon: PulseSportIcons.tennis,
      imageAsset: PulseSportIcons.tennisAsset,
    ),
    SportOption(
      key: 'table_tennis',
      title: 'Table Tennis',
      subtitle: 'Ping pong indoor table competition',
      icon: PulseSportIcons.tableTennis,
      imageAsset: PulseSportIcons.tableTennisAsset,
    ),
    SportOption(
      key: 'badminton',
      title: 'Badminton',
      subtitle: 'High-speed shuttlecock racket game',
      icon: PulseSportIcons.badminton,
      imageAsset: PulseSportIcons.badmintonAsset,
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

    if (configuredNorm.isEmpty) return _sports;

    final filtered = _sports.where((s) {
      final normKey = s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      return configuredNorm.contains(normKey);
    }).toList();

    return filtered.isNotEmpty ? filtered : _sports;
  }

  List<SportOption> get _displayedSports {
    if (_isSportsExpanded || _availableSports.length <= 2) {
      return _availableSports;
    }

    final topSports = _availableSports.take(2).toList();
    final selectedIdx = _availableSports.indexWhere((s) => s.key == _selectedSport);
    if (selectedIdx >= 2) {
      return [_availableSports.first, _availableSports[selectedIdx]];
    }

    return topSports;
  }

  Widget _buildCompressedStackPreview(bool isDarkMode) {
    return Column(
      children: [
        Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: PulseColors.getCard(isDarkMode).withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(
              color: PulseColors.getBorder(isDarkMode),
              width: 1.0,
            ),
          ),
        ),
        Container(
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: PulseColors.getCard(isDarkMode).withValues(alpha: 0.35),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            border: Border.all(
              color: PulseColors.getBorder(isDarkMode).withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpandToggleButton(int totalCount, bool isDarkMode) {
    return InkWell(
      onTap: () {
        setState(() {
          _isSportsExpanded = !_isSportsExpanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: PulseColors.getSurface(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PulseColors.getBorder(isDarkMode),
            width: 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSportsExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: PulseColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                _isSportsExpanded
                    ? 'SHOW LESS'
                    : 'SEE ALL SPORTS ($totalCount)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: PulseColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    if (widget.initialSport != null && widget.initialSport!.isNotEmpty) {
      final norm = widget.initialSport!.toLowerCase().replaceAll(' ', '_');
      if (_sports.any((s) => s.key == norm)) {
        _selectedSport = norm;
        return;
      }
    }
    final available = _availableSports;
    if (available.isNotEmpty) {
      final user = AuthService.currentUser;
      final primaryNorm = user?.primarySport.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final hasPrimary = available.any((s) => s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim() == primaryNorm);
      _selectedSport = (hasPrimary && primaryNorm != null)
          ? available.firstWhere((s) => s.key.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim() == primaryNorm).key
          : available.first.key;
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
                    ? PulseColors.primary
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary
              : PulseColors.getCard(_isDarkMode),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : PulseColors.getTextPrimary(_isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildVenueSection() {
    final isDark = _isDarkMode;
    final cardColor = PulseColors.getCard(isDark);
    final surfaceColor = PulseColors.getSurface(isDark);
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
                  '2. Venue & Location',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PulseColors.accent,
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
                borderSide: BorderSide.none,
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
                borderSide: BorderSide.none,
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
                  '2. Venue & Location',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PulseColors.accent,
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
              border: Border.all(
                color: PulseColors.getBorder(isDark).withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Photo / Visual Sport Banner
                _buildSelectedVenueBanner(isDark),

                // Venue Details & Actions
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
                        const SizedBox(height: 5),
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
                      if (_selectedCourt?.surface != null &&
                          _selectedCourt!.surface!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedCourt!.surface!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
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
                                    size: 14,
                                    color: PulseColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Change Court',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: PulseColors.accent,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Clear Selection',
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
          '2. Venue & Location',
          style: TextStyle(
            fontSize: 16,
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
              border: Border.all(
                color: PulseColors.getBorder(isDark).withValues(alpha: 0.6),
                width: 1.0,
              ),
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
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PulseColors.primary,
                    borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PulseColors.accent,
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
      height: 125,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Image or Sport-Aware Fallback Graphic
          if (hasNetworkImage)
            Image.network(
              court.imageUrl!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildSportFallbackBanner(isDark, sportKey),
            )
          else
            _buildSportFallbackBanner(isDark, sportKey),

          // 2. Natural Easing Gradient Overlay for readability & sleekness
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.70),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // 3. Floating Badges (Pills)
          Positioned(
            top: 10,
            left: 10,
            right: (court != null && court.formattedDistance.isNotEmpty) ? 80 : 10,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                if (court != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        court.isIndoor ? 'Indoor' : 'Outdoor',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Distance badge in top-right
          if (court != null && court.formattedDistance.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 10,
                        color: PulseColors.secondary,
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
            ),
        ],
      ),
    );
  }

  Widget _buildSportFallbackBanner(bool isDark, String sportKey) {
    return Container(
      width: double.infinity,
      height: 125,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF14373E),
                  const Color(0xFF0C2227),
                ]
              : [
                  const Color(0xFFD3EAEF),
                  const Color(0xFFB5DDE4),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background court line painter for authentic athletic aesthetic
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtGridLinePainter(
                lineColor: (isDark ? Colors.white : PulseColors.primary)
                    .withValues(alpha: 0.08),
              ),
            ),
          ),
          // Large stylized sport watermark icon
          Positioned(
            right: -12,
            bottom: -18,
            child: Opacity(
              opacity: isDark ? 0.16 : 0.22,
              child: PulseSportIcons.buildWidget(
                sportKey,
                size: 110,
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
    return Scaffold(
      backgroundColor: PulseColors.getBackground(_isDarkMode),
      appBar: AppBar(
        backgroundColor: PulseColors.getSurface(_isDarkMode),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: PulseBackButton(isDarkMode: _isDarkMode),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Create Match',
            style: TextStyle(
              color: PulseColors.getTextPrimary(_isDarkMode),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: PulseColors.getTextPrimary(_isDarkMode),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: PulseColors.getBorder(_isDarkMode),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Select Sport
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '1. Select Sport',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                    ),
                  ),
                  if (_availableSports.length > 2)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSportsExpanded = !_isSportsExpanded;
                        });
                      },
                      child: Text(
                        _isSportsExpanded ? 'Collapse' : 'Expand (${_availableSports.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PulseColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    ..._displayedSports.map(
                      (sport) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: SportSelectorCard(
                          option: sport,
                          isSelected: _selectedSport == sport.key,
                          isDarkMode: _isDarkMode,
                          onTap: () {
                            setState(() {
                              _selectedSport = sport.key;
                            });
                          },
                        ),
                      ),
                    ),
                    if (!_isSportsExpanded && _availableSports.length > 2)
                      _buildCompressedStackPreview(_isDarkMode),
                    if (_availableSports.length > 2)
                      _buildExpandToggleButton(_availableSports.length, _isDarkMode),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Step 2: Venue & Location
              _buildVenueSection(),

              const SizedBox(height: 24),

              // Step 3: Match Time (Today Only)
              Text(
                '3. Schedule Time (Today)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Read-Only Date Display (Today)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: PulseColors.getCard(_isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.today, size: 20, color: PulseColors.primary),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: PulseColors.getTextPrimary(_isDarkMode),
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
                  const SizedBox(width: 12),
                  // Time Picker Button
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: PulseColors.getCard(_isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: PulseColors.primary),
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: PulseColors.getTextPrimary(_isDarkMode),
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

              // Step 4: Custom Scoring Rules
              Text(
                '4. Custom Scoring Rules',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.getCard(_isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of Sets
                    Text(
                      'Match Format (Total Sets)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.getTextSecondary(_isDarkMode),
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

                    const SizedBox(height: 16),

                    // Target Points per Set
                    Text(
                      'Points to Win Set',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.getTextSecondary(_isDarkMode),
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

                    const SizedBox(height: 16),

                    // Win by 2 points switch
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: PulseColors.getTextPrimary(_isDarkMode),
                                ),
                              ),
                              Text(
                                'Must lead by at least 2 points to win set',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PulseColors.getTextSecondary(_isDarkMode),
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
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : PulseColors.primary,
                          ),
                          activeTrackColor: PulseColors.primary,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          onChanged: (val) => setState(() => _winByTwo = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Match Summary Card (Clean Fill, No Heavy Border)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.getCard(_isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: PulseColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Match Setup Summary',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: PulseColors.getTextPrimary(_isDarkMode),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                      '${_totalSets == 1 ? "1 Set" : "Best of $_totalSets Sets"} ($_pointsToWinSet pts/set${_winByTwo ? ", win by 2" : ""})',
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
                        color: PulseColors.getBorder(_isDarkMode).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Next Step',
                      'Invite Player 2 & Assign Scorer',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreateMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0, // STRICT NO DROP SHADOW
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: PulseColors.primary),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ..strokeWidth = 1.5;

    // Stylized outer court perimeter
    final courtRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(8),
    );
    canvas.drawRRect(courtRect, paint);

    // Center divider line / net line
    canvas.drawLine(
      Offset(size.width / 2, 12),
      Offset(size.width / 2, size.height - 12),
      paint,
    );

    // Horizontal baseline / service divide
    canvas.drawLine(
      Offset(12, size.height / 2),
      Offset(size.width - 12, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtGridLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
