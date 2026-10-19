import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalVehicles, LocalCatalogServices, LocalQuotes, SyncQueueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(localCatalogServices);
            await m.createTable(localQuotes);
          }
        },
      );

  static QueryExecutor openConnection() => driftDatabase(name: 'mechupp_local');
}
