// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/public_tracking_out.dart';
import '../models/tracking_link_out.dart';

part 'tracking_client.g.dart';

@RestApi()
abstract class TrackingClient {
  factory TrackingClient(Dio dio, {String? baseUrl}) = _TrackingClient;

  /// Create Tracking Link
  @POST('/v1/bookings/{booking_id}/tracking-links')
  Future<TrackingLinkOut> createTrackingLinkV1BookingsBookingIdTrackingLinksPost({
    @Path('booking_id') required String bookingId,
    @Header('authorization') String? authorization,
  });

  /// Get Public Tracking
  @GET('/v1/public/tracking/{token}')
  Future<PublicTrackingOut> getPublicTrackingV1PublicTrackingTokenGet({
    @Path('token') required String token,
  });
}
