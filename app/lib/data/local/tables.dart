import 'package:drift/drift.dart';

class LocalVehicles extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get vehicleType => text()();
  TextColumn get brand => text()();
  TextColumn get model => text()();
  TextColumn get registrationNumber => text()();
  IntColumn get year => integer()();
  TextColumn get fuelType => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get odometerKm => integer().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get insuranceExpiry => text().nullable()();
  TextColumn get pucExpiry => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get state => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
