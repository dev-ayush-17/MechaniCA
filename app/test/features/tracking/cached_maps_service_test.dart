import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/tracking/data/adapters/google_maps_service.dart';
import 'package:mechupp_app/features/tracking/data/cached_maps_service.dart';
import 'package:mechupp_app/features/tracking/data/fake_maps_service.dart';
import 'package:mechupp_app/features/tracking/domain/maps_service.dart';

void main() {
  const originLat = 25.5941;
  const originLng = 85.1376;
  const destLat = 25.61;
  const destLng = 85.14;

  Future<void> route(CachedMapsService maps, {double lat = originLat}) {
    return maps.route(
      originLat: lat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
  }

  test('route cache hits within 30 seconds', () async {
    final inner = FakeMapsService();
    final clock = FakeClock(DateTime.utc(2026, 6, 1, 10));
    final maps = CachedMapsService(inner: inner, clock: clock);

    await route(maps);
    await route(maps);
    expect(inner.routeCalls, 1);

    clock.advance(const Duration(seconds: 29));
    await route(maps);
    expect(inner.routeCalls, 1);
  });

  test('route cache misses after 30 seconds', () async {
    final inner = FakeMapsService();
    final clock = FakeClock(DateTime.utc(2026, 6, 1, 10));
    final maps = CachedMapsService(inner: inner, clock: clock);

    await route(maps);
    clock.advance(const Duration(seconds: 30));
    await route(maps);
    expect(inner.routeCalls, 2);
  });

  test('route cache misses when origin moves more than 300 m', () async {
    final inner = FakeMapsService();
    final clock = FakeClock(DateTime.utc(2026, 6, 1, 10));
    final maps = CachedMapsService(inner: inner, clock: clock);

    await route(maps);
    await route(maps, lat: originLat + 0.004);
    expect(inner.routeCalls, 2);
  });

  test('failed routes are not cached', () async {
    final inner = FakeMapsService(failRoute: true);
    final clock = FakeClock(DateTime.utc(2026, 6, 1, 10));
    final maps = CachedMapsService(inner: inner, clock: clock);

    final first = await maps.route(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    expect(first, isA<Err<RouteSummary>>());
    inner.failRoute = false;
    await route(maps);
    expect(inner.routeCalls, 2);
  });

  test('google adapter refuses an empty key', () {
    expect(
      () => GoogleMapsService(dio: Dio(), apiKey: ''),
      throwsArgumentError,
    );
  });
}
