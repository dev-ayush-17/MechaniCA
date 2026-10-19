import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../domain/vehicle.dart';
import 'sync_queue_kinds.dart';

class VehicleLocalStore {
  VehicleLocalStore(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<List<Vehicle>> listVehicles(String ownerId) async {
    final rows = await (_db.select(_db.localVehicles)
          ..where((t) => t.ownerId.equals(ownerId)))
        .get();
    return rows.map(_vehicleFromRow).toList();
  }

  Future<void> upsertVehicle(Vehicle vehicle, {required bool pendingSync}) async {
    await _db.into(_db.localVehicles).insertOnConflictUpdate(
          LocalVehiclesCompanion.insert(
            id: vehicle.id,
            ownerId: vehicle.ownerId,
            vehicleType: vehicleTypeToApi(vehicle.vehicleType),
            brand: vehicle.brand,
            model: vehicle.model,
            registrationNumber: vehicle.registrationNumber,
            year: vehicle.year,
            fuelType: Value(vehicle.fuelType),
            color: Value(vehicle.color),
            odometerKm: Value(vehicle.odometerKm),
            isPrimary: Value(vehicle.isPrimary),
            insuranceExpiry: Value(vehicle.insuranceExpiry),
            pucExpiry: Value(vehicle.pucExpiry),
            createdAt: vehicle.createdAt,
            updatedAt: vehicle.updatedAt,
            version: Value(vehicle.version),
            pendingSync: Value(pendingSync),
          ),
        );
  }

  Future<void> removeVehicle(String vehicleId) async {
    await (_db.delete(_db.localVehicles)..where((t) => t.id.equals(vehicleId))).go();
  }

  Future<void> enqueue(String userId, String kind, Map<String, dynamic> payload) async {
    SyncQueueKinds.assertVehicleKind(kind);
    final now = DateTime.now().toUtc();
    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            id: _uuid.v4(),
            userId: userId,
            kind: kind,
            payloadJson: jsonEncode(payload),
            nextAttemptAt: now,
          ),
        );
  }

  Future<List<SyncQueueEntry>> pendingEntries(String userId) async {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.userId.equals(userId) & t.state.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.nextAttemptAt)]))
        .get();
  }

  Future<void> markDone(String entryId) async {
    await (_db.update(_db.syncQueueEntries)..where((t) => t.id.equals(entryId))).write(
      const SyncQueueEntriesCompanion(state: Value('done')),
    );
  }

  Vehicle _vehicleFromRow(LocalVehicle row) => Vehicle(
        id: row.id,
        ownerId: row.ownerId,
        vehicleType: vehicleTypeFromApi(row.vehicleType),
        brand: row.brand,
        model: row.model,
        year: row.year,
        registrationNumber: row.registrationNumber,
        fuelType: row.fuelType,
        color: row.color,
        odometerKm: row.odometerKm,
        isPrimary: row.isPrimary,
        insuranceExpiry: row.insuranceExpiry,
        pucExpiry: row.pucExpiry,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        version: row.version,
      );
}
