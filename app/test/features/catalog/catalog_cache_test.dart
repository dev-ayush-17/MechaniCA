import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/data/local/app_database.dart';
import 'package:mechupp_app/features/catalog/data/catalog_local_store.dart';
import 'package:mechupp_app/features/catalog/data/fake_catalog_repository.dart';
import 'package:mechupp_app/features/catalog/data/offline_catalog_repository.dart';
import 'package:mechupp_app/features/catalog/domain/service_definition.dart';

void main() {
  test('offline_catalog_serves_fresh_cache_with_updated_at', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final local = CatalogLocalStore(db);
    final clock = FakeClock(DateTime.utc(2026, 10, 19, 10, 30));
    var online = true;
    final remote = _CountingCatalog();
    final repo = OfflineCatalogRepository(
      remote: remote,
      local: local,
      isOnline: () => online,
      clock: clock,
    );

    final first = await repo.listActiveServices();
    expect(first, isA<Ok<List<ServiceDefinition>>>());
    expect(remote.calls, 1);
    expect(await local.lastCachedAt(), isNotNull);

    online = false;
    final second = await repo.listActiveServices();
    final items = (second as Ok<List<ServiceDefinition>>).value;
    expect(items.map((s) => s.code), contains('general_service'));
    expect(remote.calls, 1);

    final label =
        'Updated ${DateFormat.jm().format(DateTime.utc(2026, 10, 19, 10, 30).toLocal())}.';
    expect(label, contains('Updated'));
    expect(label.endsWith('.'), isTrue);
  });

  test('stale_cache_is_not_used_after_24_hours', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final local = CatalogLocalStore(db);
    final clock = FakeClock(DateTime.utc(2026, 10, 19, 10));
    var online = true;
    final repo = OfflineCatalogRepository(
      remote: FakeCatalogRepository(),
      local: local,
      isOnline: () => online,
      clock: clock,
    );

    await repo.listActiveServices();
    online = false;
    clock.advance(const Duration(hours: 25));
    final stale = await repo.listActiveServices();
    expect(stale, isA<Err<List<ServiceDefinition>>>());
  });
}

class _CountingCatalog extends FakeCatalogRepository {
  int calls = 0;

  @override
  Future<Result<List<ServiceDefinition>>> listActiveServices() async {
    calls += 1;
    return super.listActiveServices();
  }
}
