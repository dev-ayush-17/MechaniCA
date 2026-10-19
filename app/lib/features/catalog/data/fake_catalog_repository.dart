import '../../../core/error/result.dart';
import '../domain/catalog_repository.dart';
import '../domain/seed_services.dart';
import '../domain/service_definition.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository([List<ServiceDefinition>? services])
      : _services = {
          for (final item in services ?? seedServices) item.code: item,
        };

  final Map<String, ServiceDefinition> _services;

  @override
  Future<Result<List<ServiceDefinition>>> listActiveServices() async {
    final active = _services.values.where((s) => s.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Ok(active);
  }

  @override
  Future<Result<ServiceDefinition?>> getService(String code) async {
    return Ok(_services[code]);
  }
}
