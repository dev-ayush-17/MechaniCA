import 'package:dio/dio.dart';

import '../../../../core/error/result.dart';
import '../../domain/location_point.dart';
import '../../domain/maps_service.dart';

/// Google Geocoding + Directions over HTTPS. Bind only when [apiKey] is set.
class GoogleMapsService implements MapsService {
  GoogleMapsService({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey {
    if (apiKey.isEmpty) {
      throw ArgumentError('Google Maps requires a key.');
    }
  }

  final Dio _dio;
  final String _apiKey;

  static const _geocode = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const _directions =
      'https://maps.googleapis.com/maps/api/directions/json';

  @override
  Future<Result<GeoPoint>> geocode(String address) async {
    final payload = await _get(_geocode, {'address': address});
    return payload.when(
      onOk: (body) {
        final results = body['results'];
        if (results is! List || results.isEmpty) {
          return const Err(NotFound('We could not find that address.'));
        }
        final loc = (results.first as Map)['geometry']?['location'];
        if (loc is! Map) {
          return const Err(NotFound('We could not find that address.'));
        }
        return Ok(
          GeoPoint(
            lat: (loc['lat'] as num).toDouble(),
            lng: (loc['lng'] as num).toDouble(),
          ),
        );
      },
      onErr: (failure) => Err(failure),
    );
  }

  @override
  Future<Result<String>> reverseGeocode(LocationPoint point) async {
    final payload = await _get(_geocode, {
      'latlng': '${point.lat},${point.lng}',
    });
    return payload.when(
      onOk: (body) {
        final results = body['results'];
        if (results is! List || results.isEmpty) {
          return const Err(NotFound('We could not find that address.'));
        }
        final formatted = (results.first as Map)['formatted_address'];
        return Ok(formatted is String ? formatted : 'Unknown');
      },
      onErr: (failure) => Err(failure),
    );
  }

  @override
  Future<Result<RouteSummary>> route({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final payload = await _get(_directions, {
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
    });
    return payload.when(
      onOk: (body) {
        final routes = body['routes'];
        if (routes is! List || routes.isEmpty) {
          return const Err(NotFound('We could not find a route.'));
        }
        final route = routes.first as Map;
        final legs = route['legs'];
        if (legs is! List || legs.isEmpty) {
          return const Err(NotFound('We could not find a route.'));
        }
        final leg = legs.first as Map;
        final distance = leg['distance'];
        final duration = leg['duration'];
        if (distance is! Map || duration is! Map) {
          return const Err(Unavailable());
        }
        final polyline = route['overview_polyline'];
        final points = polyline is Map ? polyline['points'] : null;
        return Ok(
          RouteSummary(
            distanceM: (distance['value'] as num).toInt(),
            durationS: (duration['value'] as num).toInt(),
            encodedPolyline: points is String ? points : '',
          ),
        );
      },
      onErr: (failure) => Err(failure),
    );
  }

  Future<Result<Map<String, dynamic>>> _get(
    String url,
    Map<String, String> params,
  ) async {
    if (!url.startsWith('https://')) {
      return const Err(Unavailable());
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {...params, 'key': _apiKey},
      );
      final body = response.data;
      if (body == null) return const Err(Unavailable());
      final status = body['status'] as String? ?? '';
      if (status == 'ZERO_RESULTS' || status == 'NOT_FOUND') {
        return const Err(NotFound());
      }
      if (status != 'OK') {
        return const Err(Unavailable());
      }
      return Ok(body);
    } on DioException {
      return const Err(Unavailable('Maps is unavailable. Try again.'));
    }
  }
}
