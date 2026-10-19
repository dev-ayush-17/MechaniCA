import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../domain/catalog_repository.dart';
import '../domain/service_definition.dart';
import 'catalog_local_store.dart';

const catalogCacheTtl = Duration(hours: 24);

class OfflineCatalogRepository implements CatalogRepository {
  OfflineCatalogRepository({
    required CatalogRepository remote,
    required CatalogLocalStore local,
    required bool Function() isOnline,
    required Clock clock,
  })  : _remote = remote,
        _local = local,
        _isOnline = isOnline,
        _clock = clock;

  final CatalogRepository _remote;
  final CatalogLocalStore _local;
  final bool Function() _isOnline;
  final Clock _clock;

  @override
  Future<Result<List<ServiceDefinition>>> listActiveServices() async {
    if (_isOnline()) {
      final remote = await _remote.listActiveServices();
      return remote.when(
        onOk: (items) async {
          await _local.saveServices(items, _clock.now());
          return Ok(items);
        },
        onErr: (failure) async {
          final cached = await _freshCache();
          if (cached != null) return Ok(cached);
          return Err(failure);
        },
      );
    }
    final cached = await _freshCache();
    if (cached != null) return Ok(cached);
    return const Err(Unavailable('Catalog is unavailable offline.'));
  }

  @override
  Future<Result<ServiceDefinition?>> getService(String code) async {
    final listed = await listActiveServices();
    return listed.when(
      onOk: (items) {
        for (final item in items) {
          if (item.code == code) return Ok(item);
        }
        return const Ok(null);
      },
      onErr: Err.new,
    );
  }

  Future<List<ServiceDefinition>?> _freshCache() async {
    final cachedAt = await _local.lastCachedAt();
    if (cachedAt == null) return null;
    if (_clock.now().difference(cachedAt) > catalogCacheTtl) return null;
    final items = await _local.loadServices();
    if (items.isEmpty) return null;
    return items;
  }
}
