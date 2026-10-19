import 'dart:convert';

import '../../../core/error/result.dart';
import '../domain/vehicle.dart';
import 'sync_queue_kinds.dart';
import 'vehicle_local_store.dart';
import 'vehicle_remote_data_source.dart';

class VehicleSyncWorker {
  VehicleSyncWorker({
    required VehicleLocalStore local,
    required VehicleRemotePort remote,
  })  : _local = local,
        _remote = remote;

  final VehicleLocalStore _local;
  final VehicleRemotePort _remote;

  Future<Result<void>> flush(String ownerId) async {
    final entries = await _local.pendingEntries(ownerId);
    for (final entry in entries) {
      SyncQueueKinds.assertVehicleKind(entry.kind);
      if (entry.kind == SyncQueueKinds.vehicleDelete) {
        final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        final vehicleId = payload['vehicleId'] as String;
        final result = await _remote.delete(vehicleId);
        if (result case Err()) {
          return result;
        }
        await _local.markDone(entry.id);
        continue;
      }
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final draft = _vehicleFromPayload(payload);
      final result = draft.version <= 1
          ? await _remote.create(draft, idempotencyKey: entry.id)
          : await _remote.patch(draft);
      if (result case Err(:final failure)) {
        return Err(failure);
      }
      if (result case Ok(:final value)) {
        await _local.upsertVehicle(value, pendingSync: false);
        await _local.markDone(entry.id);
      }
    }
    return const Ok(null);
  }

  Vehicle _vehicleFromPayload(Map<String, dynamic> payload) {
    final now = DateTime.now().toUtc();
    return Vehicle(
      id: payload['id'] as String,
      ownerId: payload['ownerId'] as String,
      vehicleType: vehicleTypeFromApi(payload['vehicleType'] as String),
      brand: payload['brand'] as String,
      model: payload['model'] as String,
      year: payload['year'] as int,
      registrationNumber: payload['registrationNumber'] as String,
      fuelType: payload['fuelType'] as String?,
      color: payload['color'] as String?,
      odometerKm: payload['odometerKm'] as int?,
      isPrimary: payload['isPrimary'] as bool? ?? false,
      createdAt: now,
      updatedAt: now,
      version: payload['version'] as int? ?? 1,
    );
  }
}
