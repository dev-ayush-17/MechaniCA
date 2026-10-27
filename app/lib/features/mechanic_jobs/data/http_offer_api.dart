import 'package:dio/dio.dart';

import '../../../core/api/generated/models/offer_out.dart';
import '../../../core/api/generated/offers/offers_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/job_offer.dart';
import '../domain/offer_api.dart';

class HttpOfferApi implements OfferApi {
  HttpOfferApi({
    required OffersClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final OffersClient _client;
  final Future<String?> Function() _token;

  Future<String?> _auth() async {
    final token = await _token();
    return token == null ? null : 'Bearer $token';
  }

  @override
  Future<Result<JobOffer>> getOpen() async {
    try {
      final body = await _client.getOpenOfferV1OffersOpenGet(
        authorization: await _auth(),
      );
      return Ok(_map(body));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Err(NotFound('No open offer.'));
      }
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<JobOffer>> getById(String offerId) async {
    try {
      final body = await _client.getOfferV1OffersOfferIdGet(
        offerId: offerId,
        authorization: await _auth(),
      );
      return Ok(_map(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> accept(String offerId) async {
    try {
      await _client.acceptOfferV1OffersOfferIdAcceptPost(
        offerId: offerId,
        authorization: await _auth(),
      );
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> reject(String offerId) async {
    try {
      await _client.rejectOfferV1OffersOfferIdRejectPost(
        offerId: offerId,
        authorization: await _auth(),
      );
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  JobOffer _map(OfferOut body) => JobOffer(
        id: body.id,
        bookingId: body.bookingId,
        serviceName: body.serviceName,
        vehicleType: body.vehicleType,
        distanceKm: body.distanceKm.toDouble(),
        totalPaise: body.totalPaise,
        expiresAt: body.expiresAt,
        attempt: body.attempt,
      );
}
