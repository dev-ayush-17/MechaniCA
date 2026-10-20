import 'package:dio/dio.dart';

import '../../../core/api/generated/export.dart' as api;
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/parts_proof.dart';

class HttpPartsProofRepository implements PartsProofRepository {
  HttpPartsProofRepository({required api.RestClient client}) : _client = client;

  final api.RestClient _client;

  @override
  Future<Result<PartsProof>> create({
    required String token,
    required String bookingId,
    required String lineId,
    required ProofKind kind,
  }) async {
    try {
      final out = await _client.proofs.createPartsProofV1BookingsBookingIdLinesLineIdProofsPost(
        bookingId: bookingId,
        lineId: lineId,
        body: api.CreateProofRequest(kind: _kind(kind)),
        authorization: 'Bearer $token',
      );
      return Ok(_toProof(out));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<List<PartsProof>>> list({
    required String token,
    required String bookingId,
  }) async {
    try {
      final out = await _client.proofs.listPartsProofsV1BookingsBookingIdProofsGet(
        bookingId: bookingId,
        authorization: 'Bearer $token',
      );
      return Ok(out.items.map(_toProof).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  api.ProofKind _kind(ProofKind kind) => switch (kind) {
        ProofKind.before => api.ProofKind.before,
        ProofKind.after => api.ProofKind.after,
        ProofKind.oldPart => api.ProofKind.oldPart,
      };

  PartsProof _toProof(api.ProofOut out) {
    return PartsProof(
      id: out.id,
      bookingId: out.bookingId,
      lineId: out.lineId,
      kind: ProofKind.values.firstWhere(
        (item) => item.apiValue == out.kind,
        orElse: () => ProofKind.before,
      ),
      path: out.path,
      uploadUrl: out.uploadUrl,
      hidden: out.hidden,
      metadata: out.metadata,
    );
  }
}
