import '../../../core/error/result.dart';
import 'service_definition.dart';

abstract class CatalogRepository {
  Future<Result<List<ServiceDefinition>>> listActiveServices();

  Future<Result<ServiceDefinition?>> getService(String code);
}
