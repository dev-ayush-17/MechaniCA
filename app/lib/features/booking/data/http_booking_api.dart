import 'package:dio/dio.dart';

import '../../../core/api/generated/bookings/bookings_client.dart';
import '../../../core/api/generated/models/booking_out.dart';
import '../../../core/api/generated/models/booking_mode.dart' as api;
import '../../../core/api/generated/models/cancel_booking_request.dart';
import '../../../core/api/generated/models/create_booking_request.dart';
import '../../../core/api/generated/models/payment_method.dart' as api;
import '../../../core/api/generated/models/urgency.dart' as api;
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/booking.dart';
import '../domain/booking_api.dart';

class HttpBookingApi implements BookingApi {
  HttpBookingApi({
    required BookingsClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final BookingsClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<Booking>> create({
    required String vehicleId,
    required String serviceCode,
    required String addressId,
    required String paymentMethod,
    required String mode,
    required String urgency,
    required String idempotencyKey,
    DateTime? scheduledStart,
    String couponCode = '',
  }) async {
    try {
      final token = await _token();
      final body = await _client.createBookingV1BookingsPost(
        body: CreateBookingRequest(
          vehicleId: vehicleId,
          serviceCode: serviceCode,
          addressId: addressId,
          mode: api.BookingMode.fromJson(mode),
          paymentMethod: api.PaymentMethod.fromJson(paymentMethod),
          urgency: api.Urgency.fromJson(urgency),
          scheduledStart: scheduledStart,
          couponCode: couponCode,
        ),
        idempotencyKey: idempotencyKey,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        Booking(
          id: body.id,
          displayNumber: body.displayNumber,
          status: bookingStatusFromApi(body.status),
          serviceCode: body.serviceCode,
          mode: body.mode,
          urgency: body.urgency,
          totalPaise: body.estimate.totalPaise,
          cancelFeePaise: body.cancelFeePaise,
          version: body.version,
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<Booking>> cancel(String bookingId, {required String reason}) async {
    try {
      final token = await _token();
      final body = await _client.cancelBookingV1BookingsBookingIdCancelPost(
        bookingId: bookingId,
        body: CancelBookingRequest(reason: reason),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        Booking(
          id: body.id,
          displayNumber: body.displayNumber,
          status: bookingStatusFromApi(body.status),
          serviceCode: body.serviceCode,
          mode: body.mode,
          urgency: body.urgency,
          totalPaise: body.estimate.totalPaise,
          cancelFeePaise: body.cancelFeePaise,
          version: body.version,
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<List<Booking>>> listMine() async {
    try {
      final token = await _token();
      final body = await _client.listBookingsV1BookingsGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(body.items.map(_fromOut).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  Booking _fromOut(BookingOut body) {
    return Booking(
      id: body.id,
      displayNumber: body.displayNumber,
      status: bookingStatusFromApi(body.status),
      serviceCode: body.serviceCode,
      mode: body.mode,
      urgency: body.urgency,
      totalPaise: body.estimate.totalPaise,
      cancelFeePaise: body.cancelFeePaise,
      version: body.version,
      vehicleId: body.vehicleId,
      serviceName: body.serviceName,
      addressId: body.addressId,
      scheduledStart: body.scheduledStart,
      paymentMethod: body.paymentMethod,
    );
  }
}
