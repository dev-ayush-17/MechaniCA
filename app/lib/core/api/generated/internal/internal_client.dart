// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/dispatch_timeout_request.dart';
import '../models/extra_work_timeout_request.dart';
import '../models/invoice_render_out.dart';
import '../models/job_ok.dart';
import '../models/reconcile_out.dart';
import '../models/render_invoice_request.dart';

part 'internal_client.g.dart';

@RestApi()
abstract class InternalClient {
  factory InternalClient(Dio dio, {String? baseUrl}) = _InternalClient;

  /// Render Invoice
  @POST('/v1/internal/invoices/render')
  Future<InvoiceRenderOut> renderInvoiceV1InternalInvoicesRenderPost({
    @Body() required RenderInvoiceRequest body,
    @Header('x-internal-job-token') String? xInternalJobToken,
  });

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

  /// Extra Work Timeout
  @POST('/v1/internal/jobs/extra-work-timeout')
  Future<JobOk> extraWorkTimeoutV1InternalJobsExtraWorkTimeoutPost({
    @Body() required ExtraWorkTimeoutRequest body,
    @Header('x-internal-job-token') String? xInternalJobToken,
  });

  /// Reconcile Payments
  @POST('/v1/internal/jobs/reconcile-payments')
  Future<ReconcileOut> reconcilePaymentsV1InternalJobsReconcilePaymentsPost({
    @Header('x-internal-job-token') String? xInternalJobToken,
  });
}
