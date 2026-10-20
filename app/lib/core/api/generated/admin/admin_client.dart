// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/admin_booking_list_out.dart';
import '../models/admin_coupon_list_out.dart';
import '../models/admin_coupon_out.dart';
import '../models/admin_user_list_out.dart';
import '../models/admin_user_out.dart';
import '../models/analytics_out.dart';
import '../models/audit_list_out.dart';
import '../models/create_coupon_request.dart';
import '../models/dispute_list_out.dart';
import '../models/dispute_note_request.dart';
import '../models/dispute_out.dart';
import '../models/document_list_out.dart';
import '../models/mechanic_list_out.dart';
import '../models/mechanic_out.dart';
import '../models/patch_coupon_request.dart';
import '../models/payment_out.dart';
import '../models/refund_request.dart';
import '../models/resolve_dispute_request.dart';
import '../models/revenue_out.dart';
import '../models/staff_cash_request.dart';
import '../models/suspension_request.dart';
import '../models/verification_request.dart';
import '../models/window.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Get Analytics
  @GET('/v1/admin/analytics')
  Future<AnalyticsOut> getAnalyticsV1AdminAnalyticsGet({
    @Header('authorization') String? authorization,
    @Query('days') int? days = 7,
  });

  /// List Applications
  @GET('/v1/admin/applications')
  Future<MechanicListOut> listApplicationsV1AdminApplicationsGet({
    @Header('authorization') String? authorization,
  });

  /// List Application Documents
  @GET('/v1/admin/applications/{mechanic_id}/documents')
  Future<DocumentListOut> listApplicationDocumentsV1AdminApplicationsMechanicIdDocumentsGet({
    @Path('mechanic_id') required String mechanicId,
    @Header('authorization') String? authorization,
  });

  /// List Audit
  @GET('/v1/admin/audit')
  Future<AuditListOut> listAuditV1AdminAuditGet({
    @Header('authorization') String? authorization,
  });

  /// List Admin Bookings
  @GET('/v1/admin/bookings')
  Future<AdminBookingListOut> listAdminBookingsV1AdminBookingsGet({
    @Query('status') String? status,
    @Query('city') String? city,
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
    @Header('authorization') String? authorization,
  });

  /// List Admin Coupons
  @GET('/v1/admin/coupons')
  Future<AdminCouponListOut> listAdminCouponsV1AdminCouponsGet({
    @Header('authorization') String? authorization,
  });

  /// Create Coupon
  @POST('/v1/admin/coupons')
  Future<AdminCouponOut> createCouponV1AdminCouponsPost({
    @Body() required CreateCouponRequest body,
    @Header('authorization') String? authorization,
  });

  /// Patch Coupon
  @PATCH('/v1/admin/coupons/{code}')
  Future<AdminCouponOut> patchCouponV1AdminCouponsCodePatch({
    @Path('code') required String code,
    @Body() required PatchCouponRequest body,
    @Header('authorization') String? authorization,
  });

  /// Disable Coupon
  @POST('/v1/admin/coupons/{code}/disable')
  Future<AdminCouponOut> disableCouponV1AdminCouponsCodeDisablePost({
    @Path('code') required String code,
    @Header('authorization') String? authorization,
  });

  /// List Disputes
  @GET('/v1/admin/disputes')
  Future<DisputeListOut> listDisputesV1AdminDisputesGet({
    @Header('authorization') String? authorization,
  });

  /// Add Dispute Note
  @POST('/v1/admin/disputes/{dispute_id}/notes')
  Future<DisputeOut> addDisputeNoteV1AdminDisputesDisputeIdNotesPost({
    @Path('dispute_id') required String disputeId,
    @Body() required DisputeNoteRequest body,
    @Header('authorization') String? authorization,
  });

  /// Resolve Dispute
  @POST('/v1/admin/disputes/{dispute_id}/resolve')
  Future<DisputeOut> resolveDisputeV1AdminDisputesDisputeIdResolvePost({
    @Path('dispute_id') required String disputeId,
    @Body() required ResolveDisputeRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Decide Verification
  @POST('/v1/admin/mechanics/{mechanic_id}/verification')
  Future<MechanicOut> decideVerificationV1AdminMechanicsMechanicIdVerificationPost({
    @Path('mechanic_id') required String mechanicId,
    @Body() required VerificationRequest body,
    @Header('authorization') String? authorization,
  });

  /// Staff Cash Confirm
  @POST('/v1/admin/payments/{payment_id}/cash-confirm')
  Future<PaymentOut> staffCashConfirmV1AdminPaymentsPaymentIdCashConfirmPost({
    @Path('payment_id') required String paymentId,
    @Body() required StaffCashRequest body,
    @Header('authorization') String? authorization,
  });

  /// Create Refund
  @POST('/v1/admin/refunds')
  Future<PaymentOut> createRefundV1AdminRefundsPost({
    @Body() required RefundRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Get Revenue
  @GET('/v1/admin/revenue')
  Future<RevenueOut> getRevenueV1AdminRevenueGet({
    @Header('authorization') String? authorization,
    @Query('window') Window? window = Window.today,
  });

  /// Search Users
  @GET('/v1/admin/users')
  Future<AdminUserListOut> searchUsersV1AdminUsersGet({
    @Header('authorization') String? authorization,
    @Query('q') String? q = '',
  });

  /// Suspend User
  @POST('/v1/admin/users/{user_id}/suspension')
  Future<AdminUserOut> suspendUserV1AdminUsersUserIdSuspensionPost({
    @Path('user_id') required String userId,
    @Body() required SuspensionRequest body,
    @Header('authorization') String? authorization,
  });
}
