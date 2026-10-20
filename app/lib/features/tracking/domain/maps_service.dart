import '../../../core/error/result.dart';
import 'location_point.dart';

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class RouteSummary {
  const RouteSummary({
    required this.distanceM,
    required this.durationS,
    required this.encodedPolyline,
  });

  final int distanceM;
  final int durationS;
  final String encodedPolyline;

  String get distanceText {
    if (distanceM >= 1000) {
      return '${(distanceM / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceM m';
  }

  String get etaText {
    final minutes = (durationS / 60).ceil();
    if (minutes <= 1) return '1 min';
    return '$minutes min';
  }
}

abstract interface class MapsService {
  Future<Result<GeoPoint>> geocode(String address);

  Future<Result<String>> reverseGeocode(LocationPoint point);

  Future<Result<RouteSummary>> route({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });
}
