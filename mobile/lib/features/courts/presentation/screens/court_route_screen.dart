import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_sport_icons.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../main.dart';
import '../../../matches/presentation/screens/create_match_screen.dart';
import '../../models/court_model.dart';
import '../../models/route_model.dart';
import '../../services/routing_service.dart';
import '../widgets/court_map_pin.dart';
import '../widgets/court_reviews_sheet.dart';

class CourtRouteScreen extends StatefulWidget {
  final CourtModel court;
  final LatLng? userLocation;

  const CourtRouteScreen({
    super.key,
    required this.court,
    this.userLocation,
  });

  @override
  State<CourtRouteScreen> createState() => _CourtRouteScreenState();
}

class _CourtRouteScreenState extends State<CourtRouteScreen> {
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  late LatLng _startLocation;
  late LatLng _destinationLocation;
  RouteModel? _route;
  bool _isLoading = true;
  bool _isStepsExpanded = false;

  StreamSubscription<Position>? _positionSubscription;
  bool _isFollowingUser = true;
  double _currentHeading = 0.0;

  @override
  void initState() {
    super.initState();
    // Default location fallback (e.g. Metro Manila center)
    _startLocation = widget.userLocation ?? const LatLng(14.5547, 121.0244);
    _destinationLocation = LatLng(widget.court.latitude, widget.court.longitude);

    _calculateRoute();
    _initLiveLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Initialize real-time GPS sensor tracking for walking / driving
  Future<void> _initLiveLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Fetch initial high-accuracy position
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        setState(() {
          _startLocation = LatLng(initialPos.latitude, initialPos.longitude);
          _currentHeading = initialPos.heading;
        });
        _calculateRoute();
      }

      // Stream live positions every 5 meters moved
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        if (!mounted) return;
        final newPoint = LatLng(position.latitude, position.longitude);

        setState(() {
          _startLocation = newPoint;
          _currentHeading = position.heading;
        });

        // Automatically follow player's location as they walk or drive
        if (_isFollowingUser) {
          _mapController.move(newPoint, _mapController.camera.zoom);
        }
      });
    } catch (err) {
      debugPrint('[CourtRouteScreen GPS Tracking Error]: $err');
    }
  }

  Future<void> _calculateRoute() async {
    setState(() => _isLoading = true);
    try {
      final calculated = await _routingService.fetchRoute(
        start: _startLocation,
        destination: _destinationLocation,
      );
      if (mounted) {
        setState(() {
          _route = calculated;
          _isLoading = false;
        });

        // Fit map bounds to encompass both start and destination
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = LatLngBounds.fromPoints([
            _startLocation,
            _destinationLocation,
            ...calculated.polylinePoints,
          ]);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(top: 80, bottom: 220, left: 40, right: 40),
            ),
          );
        });
      }
    } catch (err) {
      debugPrint('[CourtRouteScreen Calculate Route Error]: $err');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _recenterRoute() {
    if (_route != null && _route!.polylinePoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints([
        _startLocation,
        _destinationLocation,
        ..._route!.polylinePoints,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 80, bottom: 220, left: 40, right: 40),
        ),
      );
    } else {
      _mapController.move(_destinationLocation, 14.0);
    }
  }

  void _toggleFollowUser() {
    setState(() => _isFollowingUser = !_isFollowingUser);
    if (_isFollowingUser) {
      _mapController.move(_startLocation, 16.0);
    }
  }

  Future<void> _launchExternalMap() async {
    final query = '${widget.court.name}, ${widget.court.latitude},${widget.court.longitude}';
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getStepIcon(String? modifier, String? type) {
    if (type == 'arrive') return Icons.flag_rounded;
    if (type == 'depart') return Icons.navigation_rounded;
    if (modifier == null) return Icons.straight_rounded;
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('uturn')) return Icons.u_turn_left_rounded;
    return Icons.straight_rounded;
  }

  String get _liveDistanceText {
    final distKm = const Distance().as(LengthUnit.Kilometer, _startLocation, _destinationLocation);
    if (distKm < 1.0) {
      return '${(distKm * 1000).round()} m';
    }
    return '${distKm.toStringAsFixed(1)} km';
  }

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
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: PulseColors.getBackground(isDark),
          body: Stack(
            children: [
              // 1. Interactive Map Canvas (Mapbox High-Definition)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    (_startLocation.latitude + _destinationLocation.latitude) / 2,
                    (_startLocation.longitude + _destinationLocation.longitude) / 2,
                  ),
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (position, hasGesture) {
                    // If player manually drags the map canvas, disable auto-lock camera
                    if (hasGesture && _isFollowingUser) {
                      setState(() => _isFollowingUser = false);
                    }
                  },
                ),
                children: [
                  // Match the map style used by Court Finder for the active app theme.
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken'
                        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken',
                    userAgentPackageName: 'com.rallypulse.app',
                    maxZoom: 19.0,
                  ),

                  // Route Polyline Layer
                  if (_route != null && _route!.polylinePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route!.polylinePoints,
                          strokeWidth: 4.5,
                          color: isDark
                              ? PulseColors.secondary
                              : PulseColors.primary,
                        ),
                      ],
                    ),

                  // Markers Layer (Live User GPS + Destination Venue)
                  MarkerLayer(
                    markers: [
                      // Live Player GPS Marker with direction bearing
                      Marker(
                        point: _startLocation,
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer animated GPS halo
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Inner rotating pointer / compass
                              Transform.rotate(
                                angle: (_currentHeading * math.pi) / 180.0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                  child: Icon(
                                    _currentHeading > 0 ? Icons.navigation_rounded : Icons.person_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Destination Court Marker
                      Marker(
                        point: _destinationLocation,
                        width: 44,
                        height: 44,
                        child: CourtMapPin(
                          court: widget.court,
                          isSelected: true,
                          size: 44,
                          isDarkMode: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Top App Bar Overlay
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: PulseColors.getCard(isDark),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PulseSportIcons.getIcon(widget.court.primarySport),
                                size: 14,
                                color: isDark ? Colors.white : PulseColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.court.name,
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
                      // Follow Me / Lock GPS Camera Button
                      Container(
                        decoration: BoxDecoration(
                          color: _isFollowingUser ? PulseColors.primary : PulseColors.getCard(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _toggleFollowUser,
                          icon: Icon(
                            _isFollowingUser ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                            size: 18,
                            color: _isFollowingUser ? Colors.white : (isDark ? Colors.white : PulseColors.primary),
                          ),
                          color: _isFollowingUser ? Colors.white : (isDark ? Colors.white : PulseColors.primary),
                          tooltip: _isFollowingUser ? 'Following Location' : 'Follow Location',
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Recenter Whole Route Button
                      Container(
                        decoration: BoxDecoration(
                          color: PulseColors.getCard(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _recenterRoute,
                          icon: Icon(
                            Icons.route_rounded,
                            size: 18,
                            color: isDark ? Colors.white : PulseColors.primary,
                          ),
                          color: isDark ? Colors.white : PulseColors.primary,
                          tooltip: 'Fit Whole Route',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Loading Indicator Overlay
              if (_isLoading)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: PulseColors.getCard(isDark),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: PulseColors.primary),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Calculating route...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Bottom Route Details Sheet (In-App Overlay)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseColors.getBackground(isDark),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Indicator
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Time & Live Distance Row
                        Row(
                          children: [
                            // Travel Duration
                            Flexible(
                              child: Text(
                                _route?.formattedDuration ?? '-- min',
                                style: TextStyle(
                                  color: PulseColors.getTextPrimary(isDark),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Live Counting-Down Distance Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? PulseColors.secondary.withValues(alpha: 0.15)
                                    : PulseColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _liveDistanceText,
                                style: TextStyle(
                                  color: isDark ? PulseColors.secondary : PulseColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_route != null && _route!.steps.isNotEmpty) ...[
                              const Spacer(),
                              // Toggle Steps Button
                              TextButton.icon(
                                onPressed: () => setState(() => _isStepsExpanded = !_isStepsExpanded),
                                icon: Icon(
                                  _isStepsExpanded ? Icons.keyboard_arrow_down_rounded : Icons.list_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white : PulseColors.primary,
                                ),
                                label: Text(
                                  _isStepsExpanded ? 'Hide' : 'Steps (${_route!.steps.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white : PulseColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : PulseColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Destination Address & Community Advice Row
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 10),
                          child: Row(
                            children: [
                              if (widget.court.address != null && widget.court.address!.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    widget.court.address!,
                                    style: TextStyle(
                                      color: PulseColors.getTextSecondary(isDark),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 8),
                              // Tips & Reviews Button
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => CourtReviewsSheet(
                                      court: widget.court,
                                      isDarkMode: isDark,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.court.totalVotes > 0 && widget.court.recommendationPercent >= 70
                                        ? PulseColors.primary.withValues(alpha: 0.12)
                                        : PulseColors.getCard(isDark),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.court.totalVotes > 0 ? Icons.thumb_up_rounded : Icons.rate_review_outlined,
                                        size: 11,
                                        color: isDark
                                            ? Colors.white
                                            : (widget.court.totalVotes > 0 && widget.court.recommendationPercent >= 70
                                                ? PulseColors.primary
                                                : PulseColors.getTextSecondary(isDark)),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.court.totalVotes > 0
                                            ? '${widget.court.recommendationPercent}% Tips'
                                            : 'Tips',
                                        style: TextStyle(
                                          color: widget.court.totalVotes > 0 && widget.court.recommendationPercent >= 70
                                              ? (isDark ? Colors.white : PulseColors.primary)
                                              : PulseColors.getTextSecondary(isDark),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expandable Turn-by-Turn Maneuvers Drawer
                        if (_isStepsExpanded && _route != null && _route!.steps.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: PulseColors.getCard(isDark),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _route!.steps.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 8,
                                color: PulseColors.getTextSecondary(isDark).withValues(alpha: 0.1),
                              ),
                              itemBuilder: (context, idx) {
                                final step = _route!.steps[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStepIcon(step.modifier, step.type),
                                        size: 16,
                                        color: isDark ? Colors.white : PulseColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          step.instruction,
                                          style: TextStyle(
                                            color: PulseColors.getTextPrimary(isDark),
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        step.formattedDistance,
                                        style: TextStyle(
                                          color: PulseColors.getTextSecondary(isDark),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        // Action Buttons: "Host Match Here" & "Voice GPS"
                        Row(
                          children: [
                            // External GPS Option
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: _launchExternalMap,
                                  icon: Icon(
                                    Icons.navigation_rounded,
                                    size: 15,
                                    color: isDark ? Colors.white : PulseColors.primary,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Voice GPS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white : PulseColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : PulseColors.primary.withValues(alpha: 0.08),
                                    foregroundColor: isDark ? Colors.white : PulseColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Primary Host Match Button
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CreateMatchScreen(
                                          initialCourt: widget.court,
                                          initialVenueName: widget.court.name,
                                          initialSport: widget.court.primarySport.toLowerCase(),
                                          initialLocation: widget.court.address,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Host Match Here',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PulseColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
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
        );
      },
    );
  }
}
