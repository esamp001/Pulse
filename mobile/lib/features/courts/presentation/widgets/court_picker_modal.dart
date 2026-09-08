import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../models/court_model.dart';
import '../../services/court_service.dart';
import 'suggest_court_modal.dart';

/// Modal bottom sheet allowing players to browse, search, and select
/// registered courts, or suggest a new court if their preferred court is not listed.
/// Follows strict borderless surface fills and clean iconless typography.
class CourtPickerModal extends StatefulWidget {
  final bool isDarkMode;
  final String? initialSport;
  final ValueChanged<CourtModel>? onCourtSelected;

  const CourtPickerModal({
    super.key,
    required this.isDarkMode,
    this.initialSport,
    this.onCourtSelected,
  });

  /// Opens the CourtPickerModal bottom sheet.
  static Future<CourtModel?> show(
    BuildContext context, {
    required bool isDarkMode,
    String? initialSport,
    ValueChanged<CourtModel>? onCourtSelected,
  }) {
    return showModalBottomSheet<CourtModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourtPickerModal(
        isDarkMode: isDarkMode,
        initialSport: initialSport,
        onCourtSelected: onCourtSelected,
      ),
    );
  }

  @override
  State<CourtPickerModal> createState() => _CourtPickerModalState();
}

class _CourtPickerModalState extends State<CourtPickerModal> {
  final CourtService _courtService = CourtService();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedSport;
  bool _isLoading = true;
  List<CourtModel> _courts = [];
  Timer? _searchDebounce;

  static const List<String> _sports = [
    'All',
    'Pickleball',
    'Tennis',
    'Table Tennis',
    'Badminton',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSport = _normalizeSport(widget.initialSport) ?? 'All';
    _loadCourts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? _normalizeSport(String? sport) {
    if (sport == null || sport.isEmpty) return null;
    final lower = sport.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    for (final s in _sports) {
      if (s.toLowerCase() == lower) return s;
    }
    return null;
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    try {
      final results = await _courtService.fetchNearbyCourts(
        sport: _selectedSport != 'All' ? _selectedSport : null,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );
      if (mounted) {
        setState(() {
          _courts = results;
          _isLoading = false;
        });
      }
    } catch (err) {
      debugPrint('[CourtPickerModal Load Error]: $err');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadCourts();
    });
  }

  void _handleSelectCourt(CourtModel court) {
    widget.onCourtSelected?.call(court);
    Navigator.of(context).pop(court);
  }

  void _openSuggestCourtModal() {
    SuggestCourtModal.show(
      context,
      isDarkMode: widget.isDarkMode,
      onCourtCreated: (newCourt) {
        _handleSelectCourt(newCourt);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final surfaceColor = PulseColors.getSurface(isDark);
    final cardColor = PulseColors.getCard(isDark);
    final textPrimary = PulseColors.getTextPrimary(isDark);
    final textSecondary = PulseColors.getTextSecondary(isDark);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Header Row (Text-only actions, no icons, no borders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Match Venue',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar (Borderless fill, no icons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by court name, park, or city...',
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  fillColor: cardColor,
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ),
            const SizedBox(height: 10),

            // Sport Filter Chips (Borderless, text only, no icons)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _sports.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sport = _sports[index];
                  final isSelected = _selectedSport == sport;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSport = sport);
                      _loadCourts();
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? PulseColors.primary : cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sport,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Courts List or Empty / Loading State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: PulseColors.primary),
                    )
                  : _courts.isEmpty
                      ? _buildEmptyState(textPrimary, textSecondary, cardColor)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          itemCount: _courts.length + 1, // +1 for suggest court footer
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == _courts.length) {
                              return _buildSuggestCourtFooter(cardColor, textPrimary, textSecondary);
                            }
                            final court = _courts[index];
                            return _buildCourtItem(court, cardColor, surfaceColor, textPrimary, textSecondary);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtItem(
    CourtModel court,
    Color cardColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final hasImage = court.imageUrl != null && court.imageUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: () => _handleSelectCourt(court),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: PulseColors.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Full-width background image only when court has an image
            if (hasImage)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      court.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    // Dark overlay gradient preventing text from being unreadable
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.62),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Foreground text & tags: all-white theme colors for crisp readability
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          court.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: PulseColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      if (court.formattedDistance.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          court.formattedDistance,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PulseColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    court.address ?? court.city ?? 'Location not specified',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PulseColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTagPill(court.primarySport),
                      _buildTagPill(court.isIndoor ? 'Indoor' : 'Outdoor'),
                      if (court.surface != null && court.surface!.isNotEmpty)
                        _buildTagPill(court.surface!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: PulseColors.darkTextPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, Color cardColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No courts found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.trim().isNotEmpty
                  ? 'We could not find any courts matching "${_searchController.text.trim()}".'
                  : 'No registered courts found for this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _openSuggestCourtModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Suggest This Court',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestCourtFooter(Color cardColor, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: InkWell(
        onTap: _openSuggestCourtModal,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggest a New Court',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Can\'t find your preferred court? Add it to our community database.',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
