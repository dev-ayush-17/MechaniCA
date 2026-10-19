import 'service_definition.dart';

class CatalogSnapshot {
  const CatalogSnapshot({required this.services, this.updatedAt});

  final List<ServiceDefinition> services;
  final DateTime? updatedAt;
}
