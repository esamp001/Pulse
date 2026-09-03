import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RoutingService {
  static const String _osrmEndpoint = 'https://router.project-osrm.org/route/v1/driving';

  /// Calculate real road network route between start and destination using OSRM
  Future<RouteModel> fetchRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmEndpoint/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final double distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final double durationSeconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          // Parse geometry coordinates: [[lng, lat], ...]
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = (geometry?['coordinates'] as List<dynamic>?) ?? [];

          final polylinePoints = coords.map((c) {
            final pair = c as List<dynamic>;
            final lng = (pair[0] as num).toDouble();
            final lat = (pair[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          // Parse turn-by-turn steps
          final List<RouteStep> steps = [];
          final legs = firstRoute['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final legSteps = (legs.first as Map<String, dynamic>)['steps'] as List<dynamic>?;
            if (legSteps != null) {
              for (final s in legSteps) {
                final stepMap = s as Map<String, dynamic>;
                final maneuver = stepMap['maneuver'] as Map<String, dynamic>?;
                final name = stepMap['name']?.toString() ?? '';
                final dist = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;
                final type = maneuver?['type']?.toString();
                final modifier = maneuver?['modifier']?.toString();

                String instruction = _formatInstruction(type, modifier, name);

                steps.add(RouteStep(
                  instruction: instruction,
                  distanceMeters: dist,
                  modifier: modifier,
                  type: type,
                ));
              }
            }
          }

          return RouteModel(
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: (durationSeconds / 60.0).ceil(),
            polylinePoints: polylinePoints.isNotEmpty ? polylinePoints : [start, destination],
            steps: steps,
          );
        }
      }

      return _generateFallbackRoute(start, destination);
    } catch (_) {
      return _generateFallbackRoute(start, destination);
    }
  }

  String _formatInstruction(String? type, String? modifier, String name) {
    if (type == 'depart') {
      return name.isNotEmpty ? 'Depart onto $name' : 'Start heading to destination';
    }
    if (type == 'arrive') {
      return name.isNotEmpty ? 'Arrive at $name' : 'Arrive at court';
    }

    final dir = modifier != null ? ' $modifier' : '';
    if (name.isNotEmpty) {
      return 'Turn$dir onto $name';
    }
    return 'Turn$dir and continue';
  }

  RouteModel _generateFallbackRoute(LatLng start, LatLng destination) {
    final distanceKm = const Distance().as(LengthUnit.Kilometer, start, destination);
    final durationMinutes = (distanceKm * 2.5).ceil().clamp(5, 120);

    return RouteModel(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      polylinePoints: [
        start,
        LatLng((start.latitude + destination.latitude) / 2, (start.longitude + destination.longitude) / 2),
        destination,
      ],
      steps: [
        RouteStep(
          instruction: 'Head towards destination',
          distanceMeters: distanceKm * 500,
          type: 'depart',
        ),
        RouteStep(
          instruction: 'Arrive at court',
          distanceMeters: distanceKm * 500,
          type: 'arrive',
        ),
      ],
    );
  }
}
