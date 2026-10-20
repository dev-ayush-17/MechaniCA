import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/tracking/domain/location_filter.dart';
import 'package:mechupp_app/features/tracking/domain/location_point.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 10);
  const patnaLat = 25.5941;
  const patnaLng = 85.1376;

  LocationPoint point(double lat, double lng, DateTime at) {
    return LocationPoint(
      lat: lat,
      lng: lng,
      accuracyM: 20,
      recordedAt: at,
    );
  }

  test('stale_after_60_seconds', () {
    final p = point(patnaLat, patnaLng, now);
    expect(isStale(p, now.add(const Duration(seconds: 60))), isFalse);
    expect(isStale(p, now.add(const Duration(seconds: 61))), isTrue);
    expect(
      lastSeenLabel(p, now.add(const Duration(minutes: 3))),
      startsWith('Last seen'),
    );
  });

  test('jump_over_2km_dropped', () {
    final first = point(patnaLat, patnaLng, now);
    const jumpedLng = patnaLng + 5.0 / (111.32 * 0.902);
    final jumped = point(
      patnaLat,
      jumpedLng,
      now.add(const Duration(seconds: 5)),
    );
    expect(haversineKm(first.lat, first.lng, jumped.lat, jumped.lng), greaterThan(2));
    expect(acceptPoint(first, jumped), isNull);
    final later = point(
      patnaLat,
      jumpedLng,
      now.add(const Duration(seconds: 6)),
    );
    expect(acceptPoint(first, later), isNotNull);
  });
}
