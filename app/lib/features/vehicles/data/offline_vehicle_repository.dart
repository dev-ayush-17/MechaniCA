import 'package:uuid/uuid.dart';

import '../../../core/error/result.dart';
import '../domain/indian_plate.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_repository.dart';
import 'sync_queue_kinds.dart';
import 'vehicle_api_mapper.dart';
import 'vehicle_local_store.dart';
import 'vehicle_remote_data_source.dart';
import 'vehicle_sync_worker.dart';

/// Drift-backed repository with a vehicle-only sync queue.
class OfflineVehicleRepository implements VehicleRepository {
  bool lastWriteWasQueued = false;

  OfflineVehicleRepository({
    required VehicleLocalStore local,
    required VehicleRemotePort remote,
    required VehicleSyncWorker syncWorker,
    required bool Function() isOnline,
  })  : _local = local,
        _remote = remote,
        _syncWorker = syncWorker,
        _isOnline = isOnline;

  final VehicleLocalStore _local;
  final VehicleRemotePort _remote;
  final VehicleSyncWorker _syncWorker;
  final bool Function() _isOnline;
  static const _uuid = Uuid();

  @override
  Future<Result<List<Vehicle>>> listByOwner(String ownerId) async {
    if (_isOnline()) {
      final synced = await syncFromServer(ownerId);
      if (synced case Err()) {
        // Fall back to cache when the network fails.
      }
    }
    return Ok(await _local.listVehicles(ownerId));
  }

  @override
  Future<Result<Vehicle>> save(Vehicle vehicle) async {
    if (!vehicle.hasValidPlate) {
      return const Err(InvalidInput(invalidPlateMessage));
    }
    final draft = vehicle.id.isEmpty
        ? vehicle.copyWith(id: _uuid.v4(), updatedAt: DateTime.now().toUtc())
        : vehicle.copyWith(updatedAt: DateTime.now().toUtc());

    if (_isOnline()) {
      final remoteResult = draft.version <= 1
          ? await _remote.create(draft, idempotencyKey: _uuid.v4())
          : await _remote.patch(draft);
      return remoteResult.when(
        onOk: (saved) async {
          await _local.upsertVehicle(saved, pendingSync: false);
          return Ok(saved);
        },
        onErr: (failure) async {
          await _persistQueued(draft);
          return Ok(draft);
        },
      );
    }
    await _persistQueued(draft);
    return Ok(draft);
  }

  @override
  Future<Result<void>> delete(String vehicleId, String ownerId) async {
    await _local.removeVehicle(vehicleId);
    if (_isOnline()) {
      final result = await _remote.delete(vehicleId);
      return result.when(
        onOk: (_) async => const Ok(null),
        onErr: (_) async {
          await _local.enqueue(
            ownerId,
            SyncQueueKinds.vehicleDelete,
            {'vehicleId': vehicleId},
          );
          return const Ok(null);
        },
      );
    }
    await _local.enqueue(
      ownerId,
      SyncQueueKinds.vehicleDelete,
      {'vehicleId': vehicleId},
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> syncFromServer(String ownerId) async {
    final remote = await _remote.list();
    return remote.when(
      onOk: (items) async {
        for (final v in items) {
          await _local.upsertVehicle(v, pendingSync: false);
        }
        await _syncWorker.flush(ownerId);
        return const Ok(null);
      },
      onErr: (failure) => Err(failure),
    );
  }

  Future<void> _persistQueued(Vehicle draft) async {
    await _local.upsertVehicle(draft, pendingSync: true);
    await _local.enqueue(
      draft.ownerId,
      SyncQueueKinds.vehicleUpsert,
      vehiclePayload(draft),
    );
  }
}
