import 'dart:async';

import '../../../core/error/result.dart';
import '../domain/location_filter.dart';
import '../domain/location_point.dart';
import '../domain/location_tracking_service.dart';

class FakeLocationTrackingService implements LocationTrackingService {
  FakeLocationTrackingService({this.role = 'customer'});

  final String role;
  final Map<String, LocationSnapshot> snapshots = {};
  final _controllers = <String, StreamController<LocationSnapshot>>{};

  @override
  Future<Result<void>> publish({
    required String bookingId,
    required String role,
    required LocationPoint point,
  }) async {
    if (role != this.role) {
      return const Err(PermissionDenied('You can only publish your own location.'));
    }
    final current = snapshots[bookingId] ?? const LocationSnapshot();
    if (role == 'mechanic') {
      final kept = acceptPoint(current.mechanic, point);
      if (kept == null) return const Ok(null);
      snapshots[bookingId] = LocationSnapshot(mechanic: kept, customer: current.customer);
    } else {
      final kept = acceptPoint(current.customer, point);
      if (kept == null) return const Ok(null);
      snapshots[bookingId] = LocationSnapshot(mechanic: current.mechanic, customer: kept);
    }
    _emit(bookingId);
    return const Ok(null);
  }

  @override
  Future<Result<LocationSnapshot?>> latest(String bookingId) async {
    return Ok(snapshots[bookingId]);
  }

  @override
  Stream<LocationSnapshot> watch(String bookingId) {
    final controller = _controllers.putIfAbsent(
      bookingId,
      () => StreamController<LocationSnapshot>.broadcast(),
    );
    final current = snapshots[bookingId];
    if (current != null) {
      scheduleMicrotask(() => controller.add(current));
    }
    return controller.stream;
  }

  void seed(String bookingId, LocationSnapshot snapshot) {
    snapshots[bookingId] = snapshot;
    _emit(bookingId);
  }

  void _emit(String bookingId) {
    final snapshot = snapshots[bookingId];
    if (snapshot == null) return;
    _controllers[bookingId]?.add(snapshot);
  }
}
