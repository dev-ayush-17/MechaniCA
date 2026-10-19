// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/service_list_out.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  /// List Services
  @GET('/v1/catalog/services')
  Future<ServiceListOut> listServicesV1CatalogServicesGet({
    @Header('authorization') String? authorization,
  });
}
