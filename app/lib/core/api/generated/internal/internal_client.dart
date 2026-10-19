// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/dispatch_timeout_request.dart';
import '../models/job_ok.dart';

part 'internal_client.g.dart';

@RestApi()
abstract class InternalClient {
  factory InternalClient(Dio dio, {String? baseUrl}) = _InternalClient;

  /// Dispatch Sweep
  @POST('/v1/internal/jobs/dispatch-sweep')
  Future<JobOk> dispatchSweepV1InternalJobsDispatchSweepPost({
    @Header('x-internal-job-token') String? xInternalJobToken,
  });

  /// Dispatch Timeout
  @POST('/v1/internal/jobs/dispatch-timeout')
  Future<JobOk> dispatchTimeoutV1InternalJobsDispatchTimeoutPost({
    @Body() required DispatchTimeoutRequest body,
    @Header('x-internal-job-token') String? xInternalJobToken,
  });
}
