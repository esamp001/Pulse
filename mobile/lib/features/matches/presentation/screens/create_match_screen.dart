import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match created! Entering lobby...'),
            backgroundColor: PulseColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MatchLobbyScreen(match: createdMatch),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: PulseColors.error,
            duration: const Duration(seconds: 3),
          ),
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
                        border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
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
                          border: Border.all(color: PulseColors.getBorder(_isDarkMode)),
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

              const SizedBox(height: 28),

              // Match Summary Card (Strict Flat Border)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: PulseColors.primary),
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
                    const SizedBox(height: 8),
                    Text(
                      '• Sport: ${_sports.firstWhere((s) => s.key == _selectedSport).title}\n'
                      '• Venue: ${_venueNameController.text.isEmpty ? "(Not set)" : _venueNameController.text.trim()}\n'
                      '• Time: Today at ${_formatTimeText()}\n'
                      '• Next Step: Invite Player 2 & Assign Scorer',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: PulseColors.getTextSecondary(_isDarkMode),
                      ),
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
