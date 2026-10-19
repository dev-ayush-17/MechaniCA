import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/data/local/app_database.dart';
import 'package:mechupp_app/features/vehicles/data/offline_vehicle_repository.dart';
import 'package:mechupp_app/features/vehicles/data/sync_queue_kinds.dart';
import 'package:mechupp_app/features/vehicles/data/vehicle_local_store.dart';
import 'package:mechupp_app/features/vehicles/data/vehicle_remote_data_source.dart';
import 'package:mechupp_app/features/vehicles/data/vehicle_sync_worker.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle.dart';

void main() {
  test('queue_has_no_booking_create_kind', () {
    expect(SyncQueueKinds.isBookingCreate('booking_create'), isTrue);
    expect(
      () => SyncQueueKinds.assertVehicleKind('booking_create'),
      throwsArgumentError,
    );
  });

  test('offline_edit_queues_and_flushes', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final local = VehicleLocalStore(db);
    final remote = _TestRemote(online: false);
    final worker = VehicleSyncWorker(local: local, remote: remote);
    final repo = OfflineVehicleRepository(
      local: local,
      remote: remote,
      syncWorker: worker,
      isOnline: () => remote.online,
    );

    const owner = 'user_1';
    final draft = Vehicle(
      id: '',
      ownerId: owner,
      vehicleType: VehicleType.twoWheeler,
      brand: 'Hero',
      model: 'Splendor',
      year: 2020,
      registrationNumber: 'BR01AB1234',
      color: 'Red',
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 1, 1),
    );

    final saved = await repo.save(draft);
    expect(saved, isA<Ok<Vehicle>>());
    final pending = await local.pendingEntries(owner);
    expect(pending, hasLength(1));
    expect(pending.first.kind, SyncQueueKinds.vehicleUpsert);

    remote.online = true;
    final flush = await worker.flush(owner);
    expect(flush, isA<Ok<void>>());
    expect(remote.createCalls, 1);
    expect(await local.pendingEntries(owner), isEmpty);
  });
}

class _TestRemote implements VehicleRemotePort {
  _TestRemote({required this.online});

  bool online;
  int createCalls = 0;

  @override
  Future<Result<List<Vehicle>>> list() async => const Ok([]);

  @override
  Future<Result<Vehicle>> create(Vehicle draft, {required String idempotencyKey}) async {
    if (!online) {
      return const Err(Unavailable());
    }
    createCalls++;
    return Ok(draft.copyWith(id: 'server-id', version: 1));
  }

  @override
  Future<Result<Vehicle>> patch(Vehicle vehicle) async => Ok(vehicle);

  @override
  Future<Result<void>> delete(String vehicleId) async => const Ok(null);
}
