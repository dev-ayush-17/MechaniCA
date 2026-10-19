import '../features/catalog/domain/seed_services.dart';
import '../features/catalog/domain/service_definition.dart';
import '../models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getServices();
  Future<ServiceModel> getServiceById(String id);
}

/// Legacy list port. The booking wizard reads CatalogRepository instead.
class FakeCatalogServiceRepository implements ServiceRepository {
  @override
  Future<List<ServiceModel>> getServices() async {
    return seedServices.map(_toModel).toList();
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    return seedServices.map(_toModel).firstWhere((s) => s.id == id);
  }
}

ServiceModel _toModel(ServiceDefinition service) => ServiceModel(
      id: service.code,
      name: service.name,
      description: service.description,
      price: (service.baseLaborPaise ~/ 100).toDouble(),
      iconName: 'build',
      category: 'service',
      duration: service.durationLabel,
      isPopular: service.code == 'general_service',
      includes: const [],
    );
