import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../main.dart';
import '../../services/court_service.dart';
import 'pulse_map_center_pin.dart';

/// Result returned by [CourtMapPickerModal] when confirming a new location.
class CourtMapPickerResult {
  final LatLng location;
  final String address;
  final String city;

  const CourtMapPickerResult({
    required this.location,
    this.address = '',
    this.city = '',
  });
}

class CourtMapPickerModal extends StatefulWidget {
  final LatLng initialLocation;
  final String? initialAddress;
  final String? initialCity;
  final String sport;

  const CourtMapPickerModal({
    super.key,
    required this.initialLocation,
    this.initialAddress,
    this.initialCity,
    this.sport = 'Tennis',
  });

  @override
  State<CourtMapPickerModal> createState() => _CourtMapPickerModalState();
}

class _CourtMapPickerModalState extends State<CourtMapPickerModal> {
  final CourtService _courtService = CourtService();
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  String _detectedAddress = '';
  String _detectedCity = '';
  bool _isGeocoding = false;
  bool _isLoadingGps = false;
  bool _isDraggingPin = false;
  Timer? _pinSettledDebounce;
  Timer? _geocodeDebounce;

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
    _currentCenter = widget.initialLocation;
    _detectedAddress = widget.initialAddress ?? '';
    _detectedCity = widget.initialCity ?? '';
    if (_detectedAddress.isEmpty) {
      _reverseGeocodeCenter();
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _pinSettledDebounce?.cancel();
    super.dispose();
  }

  Future<void> _reverseGeocodeCenter() async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
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
          _isGeocoding = false;
        });
      }
    } catch (err) {
      debugPrint('[CourtMapPicker reverseGeocode Error]: $err');
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  Future<void> _locateCurrentPosition() async {
    setState(() => _isLoadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingGps = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingGps = false);
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
        _isLoadingGps = false;
      });
      _mapController.move(newCenter, 16.0);
      _reverseGeocodeCenter();
    } catch (err) {
      debugPrint('[CourtMapPicker GPS Error]: $err');
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: PulseColors.getBackground(isDark),
          body: Stack(
            children: [
              // 1. Map Canvas
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation,
                  initialZoom: 15.0,
                  onPositionChanged: (camera, hasGesture) {
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
                      _geocodeDebounce?.cancel();
                      _geocodeDebounce = Timer(const Duration(milliseconds: 400), _reverseGeocodeCenter);
                    }
                    setState(() {
                      _currentCenter = camera.center;
                    });
                  },
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
                      _geocodeDebounce?.cancel();
                      _geocodeDebounce = Timer(const Duration(milliseconds: 300), _reverseGeocodeCenter);
                    }
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
                ],
              ),

              // 2. Fixed Center Pin Indicator
              Center(
                child: PulseMapCenterPin(
                  sport: widget.sport,
                  isDragging: _isDraggingPin,
                  isDark: isDark,
                ),
              ),

              // 3. Top Header Bar with Back & GPS Locate
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      PulseBackButton(
                        isDarkMode: isDark,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: PulseColors.getCard(isDark),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: isDark ? Colors.white : PulseColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _detectedAddress.isNotEmpty
                                      ? _detectedAddress
                                      : (_isGeocoding ? 'Detecting address...' : 'Drag map to drop court pin'),
                                  style: TextStyle(
                                    color: PulseColors.getTextPrimary(isDark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: PulseColors.getCard(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _locateCurrentPosition,
                          icon: _isLoadingGps
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? Colors.white : PulseColors.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.my_location_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white : PulseColors.primary,
                                ),
                          color: isDark ? Colors.white : PulseColors.primary,
                          tooltip: 'Go to my current location',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Confirmation Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseColors.getBackground(isDark),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coordinates preview pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: PulseColors.getCard(isDark),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lat: ${_currentCenter.latitude.toStringAsFixed(5)}, Lng: ${_currentCenter.longitude.toStringAsFixed(5)}${_detectedCity.isNotEmpty ? " • $_detectedCity" : ""}',
                            style: TextStyle(
                              color: PulseColors.getTextSecondary(isDark),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_detectedAddress.isEmpty) {
                                try {
                                  final geo = await _courtService.reverseGeocode(
                                    _currentCenter.latitude,
                                    _currentCenter.longitude,
                                  );
                                  if (geo.isNotEmpty) {
                                    _detectedAddress = geo['address'] ?? geo['fullAddress'] ?? '';
                                    if ((geo['city'] ?? '').isNotEmpty) {
                                      _detectedCity = geo['city']!;
                                    }
                                  }
                                } catch (_) {}
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop(CourtMapPickerResult(
                                  location: _currentCenter,
                                  address: _detectedAddress,
                                  city: _detectedCity,
                                ));
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              'Set This Court Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
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
