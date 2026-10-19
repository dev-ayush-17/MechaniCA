// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/booking_create_out.dart';
import '../models/booking_list_out.dart';
import '../models/booking_out.dart';
import '../models/cancel_request.dart';
import '../models/create_booking_request.dart';
import '../models/transition_request.dart';

part 'bookings_client.g.dart';

@RestApi()
abstract class BookingsClient {
  factory BookingsClient(Dio dio, {String? baseUrl}) = _BookingsClient;

  /// List Bookings
  @GET('/v1/bookings')
  Future<BookingListOut> listBookingsV1BookingsGet({
    @Header('authorization') String? authorization,
  });

  /// Create Booking
  @POST('/v1/bookings')
  Future<BookingCreateOut> createBookingV1BookingsPost({
    @Body() required CreateBookingRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Get Booking
  @GET('/v1/bookings/{booking_id}')
  Future<BookingOut> getBookingV1BookingsBookingIdGet({
    @Path('booking_id') required String bookingId,
    @Header('authorization') String? authorization,
  });

  /// Cancel Booking
  @POST('/v1/bookings/{booking_id}/cancel')
  Future<BookingOut> cancelBookingV1BookingsBookingIdCancelPost({
    @Path('booking_id') required String bookingId,
    @Body() required CancelRequest body,
    @Header('authorization') String? authorization,
  });

  /// Transition Booking
  @POST('/v1/bookings/{booking_id}/transitions')
  Future<BookingOut> transitionBookingV1BookingsBookingIdTransitionsPost({
    @Path('booking_id') required String bookingId,
    @Body() required TransitionRequest body,
    @Header('authorization') String? authorization,
  });
}
