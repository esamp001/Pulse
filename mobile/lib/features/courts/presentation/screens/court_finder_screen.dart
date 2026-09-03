import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../../matches/presentation/screens/create_match_screen.dart';
import '../../models/court_model.dart';
import '../../services/court_service.dart';
import '../widgets/court_card.dart';
import '../widgets/court_map_pin.dart';
import '../widgets/pulse_map_center_pin.dart';
import '../widgets/suggest_court_modal.dart';

class CourtFinderScreen extends StatefulWidget {
  final String? initialSport;

  const CourtFinderScreen({super.key, this.initialSport});

  @override
  State<CourtFinderScreen> createState() => _CourtFinderScreenState();
}

class _CourtFinderScreenState extends State<CourtFinderScreen> {
  final CourtService _courtService = CourtService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedSport;
  String _selectedCity = 'All';
  bool _isLoading = true;
  bool _isSyncingOsm = false;
  bool _isLocatingGps = false;
  bool _isMapMode = false; // Default to List of registered courts first

  LatLng _currentCenter = const LatLng(14.5995, 120.9842); // Metro Manila center default
  double _currentZoom = 14.5;
  String _detectedAddress = '';
  String _detectedCity = 'Metro Manila';
  Timer? _geocodeDebounce;
  bool _isDraggingPin = false;
  Timer? _pinSettledDebounce;

  List<CourtModel> _courts = [];
  CourtModel? _selectedCourtPreview;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  static const List<String> _sportFilters = [
    'All',
    'Pickleball',
    'Tennis',
    'Table Tennis',
    'Badminton',
  ];

  static const List<String> _cities = [
    'All',
    'Metro Manila',
    'Taguig',
    'Makati',
    'Quezon City',
    'Cebu City',
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
    _loadCourts();
    _tryAutoDetectLocation();
  }

  @override
  void dispose() {
    _pinSettledDebounce?.cancel();
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoDetectLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (mounted) {
          final userLocation = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentCenter = userLocation;
          });
          _mapController.move(userLocation, _currentZoom);
          _reverseGeocodeCenter();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    try {
      final results = await _courtService.fetchNearbyCourts(
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
        sport: _selectedSport != 'All' ? _selectedSport : null,
      );

      if (mounted) {
        setState(() {
          _courts = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _locateCurrentPosition() async {
    setState(() => _isLocatingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) PulseToast.show(context, 'Please enable device location services');
        setState(() => _isLocatingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) PulseToast.show(context, 'Location permission denied');
          setState(() => _isLocatingGps = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) PulseToast.show(context, 'Location permission denied forever');
        setState(() => _isLocatingGps = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final newCenter = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentCenter = newCenter;
        _isLocatingGps = false;
      });
      _mapController.move(newCenter, 16.0);
      _reverseGeocodeCenter();
      if (mounted) {
        PulseToast.show(context, 'Centered to your current GPS location');
      }
    } catch (err) {
      debugPrint('[CourtFinder GPS Error]: $err');
      if (mounted) {
        setState(() => _isLocatingGps = false);
        PulseToast.show(context, 'Could not determine GPS location');
      }
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (!_isDraggingPin) {
        setState(() => _isDraggingPin = true);
      }
      _pinSettledDebounce?.cancel();
      _pinSettledDebounce = Timer(const Duration(milliseconds: 220), () {
        if (mounted) {
          setState(() => _isDraggingPin = false);
        }
      });
      setState(() {
        _currentCenter = camera.center;
        _currentZoom = camera.zoom;
      });
      _geocodeDebounce?.cancel();
      _geocodeDebounce = Timer(const Duration(milliseconds: 500), _reverseGeocodeCenter);
    }
  }

  Future<void> _reverseGeocodeCenter() async {
    try {
      final geo = await _courtService.reverseGeocode(
        _currentCenter.latitude,
        _currentCenter.longitude,
      );
      if (mounted && geo.isNotEmpty) {
        setState(() {
          _detectedAddress = geo['address'] ?? geo['fullAddress'] ?? '';
          if ((geo['city'] ?? '').isNotEmpty) {
            _detectedCity = geo['city']!;
          }
        });
      }
    } catch (_) {}
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _courtService.searchLocations(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double?;
    final lon = item['lon'] as double?;
    if (lat != null && lon != null) {
      final target = LatLng(lat, lon);
      setState(() {
        _currentCenter = target;
        _detectedAddress = item['road'] ?? item['label'] ?? '';
        if ((item['city'] ?? '').toString().isNotEmpty) {
          _detectedCity = item['city'].toString();
        }
        _searchResults = [];
        _isSearching = false;
        _searchController.clear();
      });
      _mapController.move(target, 15.5);
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _triggerOsmSync() async {
    setState(() => _isSyncingOsm = true);
    PulseToast.show(context, 'Scanning OpenStreetMap for sports facilities...');
    try {
      final count = await _courtService.syncOsm(
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
        sport: _selectedSport != 'All' ? _selectedSport : null,
      );
      await _loadCourts();
      if (mounted) {
        PulseToast.show(context, count > 0 ? 'Found $count courts on OpenStreetMap!' : 'Courts are up to date.');
      }
    } catch (_) {
      if (mounted) {
        PulseToast.show(context, 'OpenStreetMap scan complete.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingOsm = false);
      }
    }
  }

  void _openRegisterModal() {
    SuggestCourtModal.show(
      context,
      isDarkMode: themeModeNotifier.value == ThemeMode.dark,
      initialLocation: _currentCenter,
      initialAddress: _detectedAddress,
      initialCity: _detectedCity,
      onCourtCreated: (newCourt) {
        setState(() {
          _courts.insert(0, newCourt);
          _selectedCourtPreview = newCourt;
          _isMapMode = false; // Return to list view to view the registered court
        });
        PulseToast.show(context, 'Court registered successfully!');
      },
    );
  }

  void _openMapForPinning() {
    setState(() {
      _isMapMode = true;
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
    PulseToast.show(context, 'Drag the map to position your court pin');
  }

  void _onHostMatch(CourtModel court) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateMatchScreen(
          initialVenueName: court.name,
          initialSport: court.primarySport.toLowerCase(),
          initialLocation: court.address,
        ),
      ),
    );
  }

  List<CourtModel> get _filteredCourts {
    final query = _searchController.text.trim().toLowerCase();
    return _courts.where((c) {
      if (_selectedSport != 'All') {
        final sportMatch = c.sports.any((s) => s.toLowerCase() == _selectedSport.toLowerCase());
        if (!sportMatch && c.primarySport.toLowerCase() != _selectedSport.toLowerCase()) {
          return false;
        }
      }
      if (_selectedCity != 'All') {
        final city = (c.city ?? '').toLowerCase();
        final addr = (c.address ?? '').toLowerCase();
        final target = _selectedCity.toLowerCase();
        if (!city.contains(target) && !addr.contains(target)) return false;
      }
      if (query.isNotEmpty) {
        final name = c.name.toLowerCase();
        final addr = (c.address ?? '').toLowerCase();
        final city = (c.city ?? '').toLowerCase();
        if (!name.contains(query) && !addr.contains(query) && !city.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        return PopScope(
          canPop: !_isMapMode,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_isMapMode) {
              setState(() => _isMapMode = false);
            }
          },
          child: Scaffold(
            backgroundColor: PulseColors.getBackground(isDark),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      PulseBackButton(
                        isDarkMode: isDark,
                        onPressed: () {
                          if (_isMapMode) {
                            setState(() => _isMapMode = false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Find Courts',
                              style: TextStyle(
                                color: PulseColors.getTextPrimary(isDark),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _isMapMode ? 'Drag pin to register location' : 'Browse registered courts',
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDark),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Switcher (Map vs List)
                      Container(
                        decoration: BoxDecoration(
                          color: PulseColors.getCard(isDark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isMapMode = !_isMapMode;
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
                          icon: Icon(
                            _isMapMode ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
                            size: 20,
                            color: isDark ? Colors.white : PulseColors.primary,
                          ),
                          color: isDark ? Colors.white : PulseColors.primary,
                          tooltip: _isMapMode ? 'Switch to List view' : 'Open Map view',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: _isMapMode
                ? _buildInteractiveMapView(isDark)
                : _buildListView(isDark),
          ),
        );
      },
    );
  }

  // --- 1. Interactive Map View ---
  Widget _buildInteractiveMapView(bool isDark) {
    return Stack(
      children: [
        // Map Canvas
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: _currentZoom,
            onPositionChanged: _onMapPositionChanged,
            onMapEvent: (event) {
              if (event is MapEventMoveStart || event is MapEventFlingAnimationStart) {
                if (!_isDraggingPin) {
                  setState(() => _isDraggingPin = true);
                }
              } else if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                _pinSettledDebounce?.cancel();
                _pinSettledDebounce = Timer(const Duration(milliseconds: 160), () {
                  if (mounted) {
                    setState(() => _isDraggingPin = false);
                  }
                });
              }
            },
            onTap: (_, _) {
              if (_selectedCourtPreview != null) {
                setState(() => _selectedCourtPreview = null);
              }
              if (_searchResults.isNotEmpty) {
                setState(() {
                  _searchResults = [];
                  _isSearching = false;
                });
              }
              FocusScope.of(context).unfocus();
            },
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
            // Registered Court Markers
            MarkerLayer(
              markers: _filteredCourts.map((court) {
                final isSelected = _selectedCourtPreview?.id == court.id;
                final markerSize = isSelected ? 48.0 : 42.0;
                return Marker(
                  point: LatLng(court.latitude, court.longitude),
                  width: markerSize,
                  height: markerSize,
                  child: CourtMapPin(
                    court: court,
                    isSelected: isSelected,
                    size: markerSize,
                    isDarkMode: isDark,
                    onTap: () {
                      setState(() => _selectedCourtPreview = court);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Movable Center Pin Indicator
        Center(
          child: PulseMapCenterPin(
            sport: _selectedSport != 'All' ? _selectedSport : 'Tennis',
            isDragging: _isDraggingPin,
            isDark: isDark,
          ),
        ),

        // Floating Search Location Bar
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchQueryChanged,
                  style: TextStyle(color: PulseColors.getTextPrimary(isDark), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search location or address...',
                    hintStyle: TextStyle(
                      color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white : PulseColors.primary,
                    ),
                    suffixIcon: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.white : PulseColors.primary,
                              ),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: isDark ? Colors.white : PulseColors.getTextSecondary(isDark),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                },
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Search Suggestions Dropdown
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: PulseColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: PulseColors.getBorder(isDark).withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      final label = item['label'] ?? item['displayName'] ?? '';
                      final city = item['city'] ?? '';

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: isDark ? Colors.white : PulseColors.primary,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: PulseColors.getTextPrimary(isDark),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: city.isNotEmpty
                            ? Text(
                                city,
                                style: TextStyle(
                                  color: PulseColors.getTextSecondary(isDark),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _selectSearchResult(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Bottom Action Panel: Selected Court Preview OR "Register this location" Banner
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _selectedCourtPreview != null
              ? _buildCourtPreviewCard(_selectedCourtPreview!, isDark)
              : _buildRegisterLocationBanner(isDark),
        ),

        // Floating Map Controls (Right Side)
        Positioned(
          right: 16,
          bottom: 165,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Locate My Location Button
              Container(
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _locateCurrentPosition,
                  icon: _isLocatingGps
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : PulseColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: isDark ? Colors.white : PulseColors.primary,
                        ),
                  color: isDark ? Colors.white : PulseColors.primary,
                  tooltip: 'Locate My Location',
                ),
              ),
              const SizedBox(height: 10),

              // OSM Scanner Button
              Container(
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSyncingOsm ? null : _triggerOsmSync,
                  icon: _isSyncingOsm
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : PulseColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.radar_rounded,
                          size: 20,
                          color: isDark ? Colors.white : PulseColors.primary,
                        ),
                  color: isDark ? Colors.white : PulseColors.primary,
                  tooltip: 'Scan OpenStreetMap Courts',
                ),
              ),
              const SizedBox(height: 10),

              // Zoom In
              Container(
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    final newZoom = (_currentZoom + 1.0).clamp(3.0, 19.0);
                    _mapController.move(_currentCenter, newZoom);
                    setState(() => _currentZoom = newZoom);
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: isDark ? Colors.white : PulseColors.getTextPrimary(isDark),
                  tooltip: 'Zoom In',
                ),
              ),
              const SizedBox(height: 6),

              // Zoom Out
              Container(
                decoration: BoxDecoration(
                  color: PulseColors.getCard(isDark),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    final newZoom = (_currentZoom - 1.0).clamp(3.0, 19.0);
                    _mapController.move(_currentCenter, newZoom);
                    setState(() => _currentZoom = newZoom);
                  },
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  color: isDark ? Colors.white : PulseColors.getTextPrimary(isDark),
                  tooltip: 'Zoom Out',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLocationBanner(bool isDark) {
    final displayAddress = _detectedAddress.isNotEmpty
        ? _detectedAddress
        : 'Lat: ${_currentCenter.latitude.toStringAsFixed(4)}, Lng: ${_currentCenter.longitude.toStringAsFixed(4)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseColors.getCard(isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: isDark ? Colors.white : PulseColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayAddress,
                  style: TextStyle(
                    color: PulseColors.getTextPrimary(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openRegisterModal,
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text(
                'Register this location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
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

  Widget _buildCourtPreviewCard(CourtModel court, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseColors.getCard(isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (court.imageUrl != null && court.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    court.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 44,
                      height: 44,
                      color: PulseColors.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.sports_tennis_rounded,
                        color: isDark ? Colors.white : PulseColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PulseSportIcons.getIcon(court.primarySport.toLowerCase()),
                    color: isDark ? Colors.white : PulseColors.primary,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: TextStyle(
                        color: PulseColors.getTextPrimary(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      court.address ?? court.city ?? 'Verified venue',
                      style: TextStyle(
                        color: PulseColors.getTextSecondary(isDark),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: isDark ? Colors.white : PulseColors.getTextSecondary(isDark),
                onPressed: () => setState(() => _selectedCourtPreview = null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _onHostMatch(court),
                    icon: const Icon(Icons.sports_score_rounded, size: 16),
                    label: const Text('Host Match Here', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Classic List View ---

  Widget _buildListView(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // List View Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: PulseColors.getCard(isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: PulseColors.getTextPrimary(isDark), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search court name or address...',
                hintStyle: TextStyle(
                  color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? Colors.white : PulseColors.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: isDark ? Colors.white : PulseColors.getTextSecondary(isDark),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Sport Filter Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _sportFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = _sportFilters[index];
              final isSelected = _selectedSport.toLowerCase() == sport.toLowerCase();

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSport = sport);
                  _loadCourts();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? PulseColors.primary : PulseColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      sport,
                      style: TextStyle(
                        color: isSelected ? Colors.white : PulseColors.getTextPrimary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // City Selector & Add Court Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: PulseColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city_rounded,
                        size: 16,
                        color: isDark ? Colors.white : PulseColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            dropdownColor: PulseColors.getCard(isDark),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isDark ? Colors.white : PulseColors.getTextSecondary(isDark),
                            ),
                            style: TextStyle(
                              color: PulseColors.getTextPrimary(isDark),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            isDense: true,
                            isExpanded: true,
                            items: _cities.map((city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCity = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMapForPinning,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: PulseColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_location_alt_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Suggest a Court',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
        const SizedBox(height: 10),

        // Court Cards List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: PulseColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourts,
                  color: PulseColors.primary,
                  child: _filteredCourts.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.location_off_rounded,
                              size: 48,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : PulseColors.getTextSecondary(isDark).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No registered courts yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PulseColors.getTextPrimary(isDark),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to register a court or venue for your community.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDark),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _openMapForPinning,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: PulseColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_location_alt_rounded, size: 16, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Suggest a Court',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredCourts.length,
                          itemBuilder: (context, index) {
                            final court = _filteredCourts[index];
                            return CourtCard(
                              court: court,
                              isDarkMode: isDark,
                              onHostMatch: () => _onHostMatch(court),
                              onCourtUpdated: (updatedCourt) {
                                setState(() {
                                  final idx = _courts.indexWhere((c) => c.id == updatedCourt.id);
                                  if (idx != -1) _courts[idx] = updatedCourt;
                                });
                              },
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
