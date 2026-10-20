// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/add_line_request.dart';
import '../models/booking_create_out.dart';
import '../models/booking_list_out.dart';
import '../models/booking_out.dart';
import '../models/cancel_booking_request.dart';
import '../models/create_booking_request.dart';
import '../models/dispute_out.dart';
import '../models/line_decision_request.dart';
import '../models/open_dispute_request.dart';
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
    @Body() required CancelBookingRequest body,
    @Header('authorization') String? authorization,
  });

  /// Open Booking Dispute
  @POST('/v1/bookings/{booking_id}/disputes')
  Future<DisputeOut> openBookingDisputeV1BookingsBookingIdDisputesPost({
    @Path('booking_id') required String bookingId,
    @Body() required OpenDisputeRequest body,
    @Header('authorization') String? authorization,
  });

  /// Add Extra Line
  @POST('/v1/bookings/{booking_id}/lines')
  Future<BookingOut> addExtraLineV1BookingsBookingIdLinesPost({
    @Path('booking_id') required String bookingId,
    @Body() required AddLineRequest body,
    @Header('authorization') String? authorization,
  });

  /// Decide Extra Line
  @POST('/v1/bookings/{booking_id}/lines/{line_id}/decision')
  Future<BookingOut> decideExtraLineV1BookingsBookingIdLinesLineIdDecisionPost({
    @Path('booking_id') required String bookingId,
    @Path('line_id') required String lineId,
    @Body() required LineDecisionRequest body,
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
