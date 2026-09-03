import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction;
  final double distanceMeters;
  final String? modifier;
  final String? type;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    this.modifier,
    this.type,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class RouteModel {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> polylinePoints;
  final List<RouteStep> steps;

  const RouteModel({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
    required this.steps,
  });

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '$hours hr $mins min' : '$hours hr';
  }
}
