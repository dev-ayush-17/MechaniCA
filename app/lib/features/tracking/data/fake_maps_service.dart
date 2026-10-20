import '../../../core/error/result.dart';
import '../domain/location_point.dart';
import '../domain/maps_service.dart';

class FakeMapsService implements MapsService {
  FakeMapsService({this.failRoute = false});

  bool failRoute;
  int routeCalls = 0;

  static const patna = GeoPoint(lat: 25.5941, lng: 85.1376);
  static const summary = RouteSummary(
    distanceM: 4200,
    durationS: 720,
    encodedPolyline: 'w}iiD}{qvM',
  );

  @override
  Future<Result<GeoPoint>> geocode(String address) async {
    if (address.trim().isEmpty) return const Err(NotFound());
    return const Ok(patna);
  }

  @override
  Future<Result<String>> reverseGeocode(LocationPoint point) async {
    return const Ok('Boring Road, Patna');
  }

  @override
  Future<Result<RouteSummary>> route({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    routeCalls += 1;
    if (failRoute) return const Err(Unavailable());
    return const Ok(summary);
  }
}
