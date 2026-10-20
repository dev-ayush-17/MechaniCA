import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/features/tracking/data/fake_location_tracking_service.dart';
import 'package:mechupp_app/features/tracking/domain/location_point.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 10);

  LocationPoint at(DateTime t, {double lat = 25.5941, double lng = 85.1376}) {
    return LocationPoint(lat: lat, lng: lng, accuracyM: 20, recordedAt: t);
  }

  test('publish_then_latest_and_watch', () async {
    final svc = FakeLocationTrackingService(role: 'mechanic');
    final first = at(now);
    final published = await svc.publish(
      bookingId: 'b1',
      role: 'mechanic',
      point: first,
    );
    expect(published, isA<Ok<void>>());
    final latest = await svc.latest('b1');
    latest.when(
      onOk: (snap) => expect(snap?.mechanic?.lat, 25.5941),
      onErr: (_) => fail('expected ok'),
    );
    expect(
      svc.watch('b1'),
      emits(isA<LocationSnapshot>().having((s) => s.mechanic?.lat, 'lat', 25.5941)),
    );
  });

  test('publish_drops_jump_and_denies_other_role', () async {
    final svc = FakeLocationTrackingService(role: 'mechanic');
    await svc.publish(bookingId: 'b1', role: 'mechanic', point: at(now));
    final jumped = at(
      now.add(const Duration(seconds: 5)),
      lng: 85.1376 + 5.0 / (111.32 * 0.902),
    );
    await svc.publish(bookingId: 'b1', role: 'mechanic', point: jumped);
    final latest = await svc.latest('b1');
    latest.when(
      onOk: (snap) => expect(snap?.mechanic?.lng, 85.1376),
      onErr: (_) => fail('expected ok'),
    );
    final denied = await svc.publish(
      bookingId: 'b1',
      role: 'customer',
      point: at(now.add(const Duration(seconds: 10))),
    );
    expect(denied, isA<Err<void>>());
  });
}
