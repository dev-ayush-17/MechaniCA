import 'package:dio/dio.dart';

import '../../../core/api/generated/catalog/catalog_client.dart';
import '../../../core/api/generated/models/service_out.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/catalog_repository.dart';
import '../domain/service_definition.dart';

class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository({
    required CatalogClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final CatalogClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<List<ServiceDefinition>>> listActiveServices() async {
    try {
      final auth = await _bearer();
      final body = await _client.listServicesV1CatalogServicesGet(
        authorization: auth,
      );
      return Ok(body.items.map(_fromOut).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
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

  Future<String?> _bearer() async {
    final token = await _token();
    return token == null ? null : 'Bearer $token';
  }

  static ServiceDefinition _fromOut(ServiceOut item) => ServiceDefinition(
        code: item.code,
        name: item.name,
        description: item.description,
        baseLaborPaise: item.baseLaborPaise,
        durationMin: item.durationMin,
        active: item.active,
        sortOrder: item.sortOrder,
      );
}
