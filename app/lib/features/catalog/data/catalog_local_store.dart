import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';
import '../../booking/domain/pricing.dart';
import '../domain/service_definition.dart';

class CatalogLocalStore {
  CatalogLocalStore(this._db);

  final AppDatabase _db;

  Future<void> saveServices(List<ServiceDefinition> services, DateTime cachedAt) async {
    await _db.transaction(() async {
      await _db.delete(_db.localCatalogServices).go();
      for (final service in services) {
        await _db.into(_db.localCatalogServices).insert(
              LocalCatalogServicesCompanion.insert(
                code: service.code,
                name: service.name,
                description: service.description,
                baseLaborPaise: service.baseLaborPaise,
                durationMin: service.durationMin,
                active: service.active,
                sortOrder: service.sortOrder,
                cachedAt: cachedAt,
              ),
            );
      }
    });
  }

  Future<List<ServiceDefinition>> loadServices() async {
    final rows = await (_db.select(_db.localCatalogServices)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows
        .map(
          (row) => ServiceDefinition(
            code: row.code,
            name: row.name,
            description: row.description,
            baseLaborPaise: row.baseLaborPaise,
            durationMin: row.durationMin,
            active: row.active,
            sortOrder: row.sortOrder,
          ),
        )
        .toList();
  }

  Future<DateTime?> lastCachedAt() async {
    final row = await (_db.select(_db.localCatalogServices)..limit(1)).getSingleOrNull();
    return row?.cachedAt;
  }

  Future<void> saveQuote(String cacheKey, PriceQuote quote, DateTime cachedAt) async {
    await _db.into(_db.localQuotes).insertOnConflictUpdate(
          LocalQuotesCompanion.insert(
            cacheKey: cacheKey,
            laborPaise: quote.laborPaise,
            partsPaise: quote.partsPaise,
            feePaise: quote.feePaise,
            discountPaise: quote.discountPaise,
            cgstPaise: quote.cgstPaise,
            sgstPaise: quote.sgstPaise,
            totalPaise: quote.totalPaise,
            cachedAt: cachedAt,
          ),
        );
  }

  Future<PriceQuote?> loadQuote(String cacheKey) async {
    final row = await (_db.select(_db.localQuotes)
          ..where((t) => t.cacheKey.equals(cacheKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return PriceQuote(
      laborPaise: row.laborPaise,
      partsPaise: row.partsPaise,
      feePaise: row.feePaise,
      discountPaise: row.discountPaise,
      cgstPaise: row.cgstPaise,
      sgstPaise: row.sgstPaise,
      totalPaise: row.totalPaise,
    );
  }
}
