import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../domain/location_filter.dart';
import '../domain/location_point.dart';
import '../domain/maps_service.dart';

const routeCacheTtl = Duration(seconds: 30);
const routeRecalcM = 300.0;

/// Caches [MapsService.route] for 30s unless the origin moves more than 300 m.
class CachedMapsService implements MapsService {
  CachedMapsService({
    required MapsService inner,
    required Clock clock,
    this.ttl = routeCacheTtl,
    this.recalcM = routeRecalcM,
  })  : _inner = inner,
        _clock = clock;

  final MapsService _inner;
  final Clock _clock;
  final Duration ttl;
  final double recalcM;
  _CachedRoute? _cached;

  @override
  Future<Result<GeoPoint>> geocode(String address) => _inner.geocode(address);

  @override
  Future<Result<String>> reverseGeocode(LocationPoint point) =>
      _inner.reverseGeocode(point);

  @override
  Future<Result<RouteSummary>> route({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final now = _clock.now();
    final cached = _cached;
    if (cached != null &&
        cached.destLat == destLat &&
        cached.destLng == destLng &&
        now.difference(cached.at) < ttl &&
        haversineKm(cached.originLat, cached.originLng, originLat, originLng) *
                1000 <
            recalcM) {
      return Ok(cached.summary);
    }
    final result = await _inner.route(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (result case Ok(:final value)) {
      _cached = _CachedRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        at: now,
        summary: value,
      );
    }
    return result;
  }
}

class _CachedRoute {
  const _CachedRoute({
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.at,
    required this.summary,
  });

  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final DateTime at;
  final RouteSummary summary;
}
