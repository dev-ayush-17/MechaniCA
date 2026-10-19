// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Health.
  ///
  /// Liveness. Touches nothing else.
  @GET('/health')
  Future<Map<String, String>> healthHealthGet();

  /// Ready.
  ///
  /// Readiness. 503 when any dependency is unhealthy.
  @GET('/health/ready')
  Future<dynamic> readyHealthReadyGet();
}
