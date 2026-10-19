// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/reconcile_out.dart';

part 'internal_client.g.dart';

@RestApi()
abstract class InternalClient {
  factory InternalClient(Dio dio, {String? baseUrl}) = _InternalClient;

  /// Reconcile Payments
  @POST('/v1/internal/jobs/reconcile-payments')
  Future<ReconcileOut> reconcilePaymentsV1InternalJobsReconcilePaymentsPost({
    @Header('x-internal-token') String? xInternalToken,
  });
}
