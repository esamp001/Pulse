import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../widgets/match_radar_pin.dart';
import '../widgets/open_match_card.dart';
import 'create_match_screen.dart';
import 'match_lobby_screen.dart';

class MatchRadarScreen extends StatefulWidget {
  final String? initialSport;

  const MatchRadarScreen({
    super.key,
    this.initialSport,
  });

  @override
  State<MatchRadarScreen> createState() => _MatchRadarScreenState();
}

class _MatchRadarScreenState extends State<MatchRadarScreen> {
  final MatchService _matchService = MatchService();
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  late String _selectedSport;
  bool _isLoading = true;
  bool _isLocatingGps = false;
  String? _joiningMatchId;

  LatLng _userLocation = const LatLng(14.5995, 120.9842); // Metro Manila fallback
  List<MatchModel> _openMatches = [];
  int _selectedMatchIndex = 0;

  static const List<String> _sportFilters = [
    'All',
    'Pickleball',
    'Tennis',
    'Table Tennis',
    'Badminton',
  ];

  String get _mapboxToken {
    try {
      if (dotenv.isInitialized) {
        final token = dotenv.get('MAPBOX_ACCESS_TOKEN', fallback: '');
        if (token.isNotEmpty) return token;
      }
    } catch (_) {}
    return 'pk.eyJ1IjoiZXNhbXAwMDEiLCJhIjoiY210a24ycTE3MDI0azJ6b2IxMzk0ZmZzbyJ9.gN06AcEqY0iiW2LIrxQ6-Q';
  }

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.initialSport ?? 'All';
    _initRadar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initRadar() async {
    await _detectLocation();
    await _loadOpenMatches();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocatingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocatingGps = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocatingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocatingGps = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _isLocatingGps = false;
        });
        _mapController.move(_userLocation, 13.5);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  Future<void> _loadOpenMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _matchService.fetchOpenMatches(
        sport: _selectedSport == 'All' ? null : _selectedSport.toLowerCase().replaceAll(' ', '_'),
        latitude: _userLocation.latitude,
        longitude: _userLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _openMatches = matches;
          _isLoading = false;
          _selectedMatchIndex = 0;
        });

        if (matches.isNotEmpty && matches.first.court != null) {
          final firstCourt = matches.first.court!;
          _mapController.move(
            LatLng(firstCourt.latitude, firstCourt.longitude),
            13.5,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PulseToast.show(context, 'Failed to refresh open matches');
      }
    }
  }

  void _onSportFilterSelected(String sport) {
    if (_selectedSport == sport) return;
    setState(() {
      _selectedSport = sport;
    });
    _loadOpenMatches();
  }

  void _onPinTapped(int index) {
    if (index >= 0 && index < _openMatches.length) {
      setState(() => _selectedMatchIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      final match = _openMatches[index];
      if (match.court != null) {
        _mapController.move(
          LatLng(match.court!.latitude, match.court!.longitude),
          14.0,
        );
      }
    }
  }

  void _onCardChanged(int index) {
    if (index >= 0 && index < _openMatches.length) {
      setState(() => _selectedMatchIndex = index);
      final match = _openMatches[index];
      if (match.court != null) {
        _mapController.move(
          LatLng(match.court!.latitude, match.court!.longitude),
          14.0,
        );
      }
    }
  }

  Future<void> _handleJoinMatch(MatchModel match) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PulseColors.getCard(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PulseColors.getBorder(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join Open Match',
                  style: TextStyle(
                    color: PulseColors.getTextPrimary(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You are about to join ${match.player1?.name ?? "Host"}\'s ${match.sportDisplayName} match at ${match.venueName}.',
                  style: TextStyle(
                    color: PulseColors.getTextSecondary(isDark),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: PulseColors.getTextSecondary(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm & Enter',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _joiningMatchId = match.id);
    try {
      final joinedMatch = await _matchService.joinOpenMatch(match.id);
      if (mounted) {
        setState(() => _joiningMatchId = null);
        PulseToast.show(context, 'Successfully joined match! Entering lobby...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MatchLobbyScreen(match: joinedMatch),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joiningMatchId = null);
        PulseToast.show(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        // Build map markers for open matches
        final markers = <Marker>[
          // Current user location pin
          Marker(
            point: _userLocation,
            width: 32,
            height: 32,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ];

        for (int i = 0; i < _openMatches.length; i++) {
          final m = _openMatches[i];
          final court = m.court;
          if (court != null) {
            final isSelected = i == _selectedMatchIndex;
            markers.add(
              Marker(
                point: LatLng(court.latitude, court.longitude),
                width: isSelected ? 56 : 46,
                height: isSelected ? 56 : 46,
                child: MatchRadarPin(
                  match: m,
                  isSelected: isSelected,
                  isDarkMode: isDark,
                  onTap: () => _onPinTapped(i),
                ),
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: PulseColors.getBackground(isDark),
          body: Stack(
            children: [
              // Interactive FlutterMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation,
                  initialZoom: 13.5,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken'
                        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken',
                    userAgentPackageName: 'com.rallypulse.app',
                    maxZoom: 19.0,
                    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Top Floating App Bar & Sports Filter Pills
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row
                      Row(
                        children: [
                          PulseBackButton(isDarkMode: isDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: PulseColors.getCard(isDark).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: PulseColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Match Radar',
                                      style: TextStyle(
                                        color: PulseColors.getTextPrimary(isDark),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isLocatingGps)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: _detectLocation,
                                      child: const Icon(
                                        Icons.gps_fixed_rounded,
                                        size: 16,
                                        color: PulseColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Sports Filter Pills Bar
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sportFilters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final sport = _sportFilters[index];
                            final isSelected = _selectedSport.toLowerCase() == sport.toLowerCase();
                            return GestureDetector(
                              onTap: () => _onSportFilterSelected(sport),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? PulseColors.primary
                                      : PulseColors.getCard(isDark).withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    sport,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : PulseColors.getTextPrimary(isDark),
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Carousel or Empty State
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _isLoading
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PulseColors.getCard(isDark),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
                              ),
                            ),
                          ),
                        )
                      : _openMatches.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PulseColors.getCard(isDark).withValues(alpha: 0.96),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.radar_rounded,
                                      size: 32,
                                      color: PulseColors.getTextSecondary(isDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'No open matches nearby',
                                      style: TextStyle(
                                        color: PulseColors.getTextPrimary(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create an open match and wait for players to join!',
                                      style: TextStyle(
                                        color: PulseColors.getTextSecondary(isDark),
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CreateMatchScreen(
                                                initialSport: _selectedSport == 'All' ? null : _selectedSport,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: PulseColors.primary,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Create Match',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 140,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _openMatches.length,
                                onPageChanged: _onCardChanged,
                                itemBuilder: (context, index) {
                                  final match = _openMatches[index];
                                  return OpenMatchCard(
                                    match: match,
                                    isDarkMode: isDark,
                                    isJoining: _joiningMatchId == match.id,
                                    onJoin: () => _handleJoinMatch(match),
                                    onTap: () => _onPinTapped(index),
                                  );
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
