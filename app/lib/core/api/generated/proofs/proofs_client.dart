// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_proof_request.dart';
import '../models/proof_list_out.dart';
import '../models/proof_out.dart';

part 'proofs_client.g.dart';

@RestApi()
abstract class ProofsClient {
  factory ProofsClient(Dio dio, {String? baseUrl}) = _ProofsClient;

  /// Create Parts Proof
  @POST('/v1/bookings/{booking_id}/lines/{line_id}/proofs')
  Future<ProofOut> createPartsProofV1BookingsBookingIdLinesLineIdProofsPost({
    @Path('booking_id') required String bookingId,
    @Path('line_id') required String lineId,
    @Body() required CreateProofRequest body,
    @Header('authorization') String? authorization,
  });

  /// List Parts Proofs
  @GET('/v1/bookings/{booking_id}/proofs')
  Future<ProofListOut> listPartsProofsV1BookingsBookingIdProofsGet({
    @Path('booking_id') required String bookingId,
    @Header('authorization') String? authorization,
  });

  /// Hide Parts Proof
  @POST('/v1/bookings/{booking_id}/proofs/{proof_id}/hide')
  Future<ProofOut> hidePartsProofV1BookingsBookingIdProofsProofIdHidePost({
    @Path('booking_id') required String bookingId,
    @Path('proof_id') required String proofId,
    @Header('authorization') String? authorization,
  });
}
