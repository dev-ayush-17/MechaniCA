import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../domain/location_filter.dart';
import '../../domain/location_point.dart';
import '../../domain/location_tracking_service.dart';

LocationTrackingService createRtdbLocationTrackingService({
  required AppConfig config,
  required String role,
}) {
  final database = FirebaseDatabase.instance;
  if (config.useFirebaseEmulator && !config.isProd) {
    database.useDatabaseEmulator(config.firebaseEmulatorHost, 9000);
  }
  return RtdbLocationTrackingService(database: database, role: role);
}

/// Client writes only `liveLocations/{bookingId}/{ownRole}`. Never writes gates.
class RtdbLocationTrackingService implements LocationTrackingService {
  RtdbLocationTrackingService({
    required FirebaseDatabase database,
    required this.role,
  }) : _db = database;

  final FirebaseDatabase _db;
  final String role;

  @override
  Future<Result<void>> publish({
    required String bookingId,
    required String role,
    required LocationPoint point,
  }) async {
    if (role != this.role) {
      return const Err(PermissionDenied('You can only publish your own location.'));
    }
    final current = await latest(bookingId);
    final previous = current.when(
      onOk: (snap) => role == 'mechanic' ? snap?.mechanic : snap?.customer,
      onErr: (_) => null,
    );
    final kept = acceptPoint(previous, point);
    if (kept == null) return const Ok(null);
    try {
      await _db.ref('liveLocations/$bookingId/$role').set(_payload(kept));
      return const Ok(null);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Err(PermissionDenied('Location sharing is closed for this job.'));
      }
      return const Err(Unavailable());
    }
  }

  @override
  Future<Result<LocationSnapshot?>> latest(String bookingId) async {
    try {
      final snap = await _db.ref('liveLocations/$bookingId').get();
      if (!snap.exists) return const Ok(null);
      return Ok(_parse(snap.value));
    } on FirebaseException {
      return const Err(Unavailable());
    }
  }

  @override
  Stream<LocationSnapshot> watch(String bookingId) {
    return _db.ref('liveLocations/$bookingId').onValue.map((event) {
      return _parse(event.snapshot.value) ?? const LocationSnapshot();
    });
  }

  Map<String, Object> _payload(LocationPoint point) {
    return {
      'lat': point.lat,
      'lng': point.lng,
      'accuracyM': point.accuracyM,
      'recordedAt': point.recordedAt.toUtc().toIso8601String(),
      if (point.speedMps != null) 'speedMps': point.speedMps!,
    };
  }

  LocationSnapshot? _parse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<Object?, Object?>.from(raw);
    return LocationSnapshot(
      mechanic: _parsePoint(map['mechanic']),
      customer: _parsePoint(map['customer']),
    );
  }

  LocationPoint? _parsePoint(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<Object?, Object?>.from(raw);
    final recorded = map['recordedAt'];
    if (recorded == null) return null;
    return LocationPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      accuracyM: (map['accuracyM'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.parse(recorded.toString()).toUtc(),
      speedMps: (map['speedMps'] as num?)?.toDouble(),
    );
  }
}
