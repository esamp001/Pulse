import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../services/match_service.dart';
import '../widgets/sport_selector_card.dart';
import 'match_lobby_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchService _matchService = MatchService();

  String _selectedSport = 'pickleball';
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  int _totalSets = 3;
  int _pointsToWinSet = 11;
  bool _winByTwo = true;

  bool _isSubmitting = false;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static const List<SportOption> _sports = [
    SportOption(
      key: 'pickleball',
      title: 'Pickleball',
      subtitle: 'Fast-paced paddle sport on a court',
      icon: Icons.sports_tennis,
    ),
    SportOption(
      key: 'tennis',
      title: 'Tennis',
      subtitle: 'Classic racket sport, sets & games',
      icon: Icons.sports_tennis_outlined,
    ),
    SportOption(
      key: 'table_tennis',
      title: 'Table Tennis',
      subtitle: 'Ping pong indoor table competition',
      icon: Icons.sports_handball,
    ),
  ];

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

  Future<void> _handleCreateMatch() async {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: PulseColors.getTextSecondary(_isDarkMode),
              fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.getBackground(_isDarkMode),
      appBar: AppBar(
        backgroundColor: PulseColors.getSurface(_isDarkMode),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Create Match',
          style: TextStyle(
            color: PulseColors.getTextPrimary(_isDarkMode),
            fontWeight: FontWeight.bold,
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
              Text(
                '1. Select Sport',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
              const SizedBox(height: 12),
              ..._sports.map(
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

              const SizedBox(height: 24),

              // Step 2: Venue & Location
              Text(
                '2. Venue & Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.getTextPrimary(_isDarkMode),
                ),
              ),
              const SizedBox(height: 12),

              // Venue Name Input
              TextFormField(
                controller: _venueNameController,
                style: TextStyle(color: PulseColors.getTextPrimary(_isDarkMode)),
                decoration: InputDecoration(
                  labelText: 'Venue Name *',
                  hintText: 'e.g. Metro Sports Club Court 3',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: PulseColors.primary),
                  fillColor: PulseColors.getCard(_isDarkMode),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PulseColors.accent, width: 2),
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

              // Address Input
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: PulseColors.getTextPrimary(_isDarkMode)),
                decoration: InputDecoration(
                  labelText: 'Address or Directions (Optional)',
                  hintText: 'e.g. 123 Main St, Downtown',
                  prefixIcon: const Icon(Icons.map_outlined, color: PulseColors.primary),
                  fillColor: PulseColors.getCard(_isDarkMode),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PulseColors.accent, width: 2),
                  ),
                ),
              ),

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(fontSize: 11, color: PulseColors.textSecondary),
                              ),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: PulseColors.getTextPrimary(_isDarkMode),
                                ),
                              ),
                            ],
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Time',
                                  style: TextStyle(fontSize: 11, color: PulseColors.textSecondary),
                                ),
                                Text(
                                  _formatTimeText(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: PulseColors.getTextPrimary(_isDarkMode),
                                  ),
                                ),
                              ],
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
                        Column(
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
                            ),
                          ],
                        ),
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
                        Text(
                          'Match Setup Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: PulseColors.getTextPrimary(_isDarkMode),
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
