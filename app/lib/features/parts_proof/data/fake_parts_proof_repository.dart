import '../../../core/error/result.dart';
import '../domain/parts_proof.dart';

class FakePartsProofRepository implements PartsProofRepository {
  final List<PartsProof> stored = [];

  @override
  Future<Result<PartsProof>> create({
    required String token,
    required String bookingId,
    required String lineId,
    required ProofKind kind,
  }) async {
    final proof = PartsProof(
      id: 'proof_${kind.apiValue}',
      bookingId: bookingId,
      lineId: lineId,
      kind: kind,
      path: 'partsProof/$bookingId/$lineId/${kind.apiValue}/fake.jpg',
      uploadUrl: 'https://storage.fake/upload/${kind.apiValue}',
      metadata: {
        'bookingId': bookingId,
        'lineId': lineId,
        'kind': kind.apiValue,
      },
    );
    stored.add(proof);
    return Ok(proof);
  }

  @override
  Future<Result<List<PartsProof>>> list({
    required String token,
    required String bookingId,
  }) async {
    return Ok(
      stored.where((item) => item.bookingId == bookingId && !item.hidden).toList(),
    );
  }
}
