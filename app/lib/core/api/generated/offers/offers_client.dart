// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/booking_accept_out.dart';
import '../models/offer_out.dart';

part 'offers_client.g.dart';

@RestApi()
abstract class OffersClient {
  factory OffersClient(Dio dio, {String? baseUrl}) = _OffersClient;

  /// Get Open Offer
  @GET('/v1/offers/open')
  Future<OfferOut> getOpenOfferV1OffersOpenGet({
    @Header('authorization') String? authorization,
  });

  /// Get Offer
  @GET('/v1/offers/{offer_id}')
  Future<OfferOut> getOfferV1OffersOfferIdGet({
    @Path('offer_id') required String offerId,
    @Header('authorization') String? authorization,
  });

  /// Accept Offer
  @POST('/v1/offers/{offer_id}/accept')
  Future<BookingAcceptOut> acceptOfferV1OffersOfferIdAcceptPost({
    @Path('offer_id') required String offerId,
    @Header('authorization') String? authorization,
  });

  /// Reject Offer
  @POST('/v1/offers/{offer_id}/reject')
  Future<void> rejectOfferV1OffersOfferIdRejectPost({
    @Path('offer_id') required String offerId,
    @Header('authorization') String? authorization,
  });
}
