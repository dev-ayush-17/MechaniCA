import '../../../core/error/result.dart';

class MaskedCall {
  const MaskedCall({required this.dialNumber, required this.expiresAt});

  final String dialNumber;
  final DateTime expiresAt;
}

abstract interface class TelephonyPort {
  Future<Result<MaskedCall>> mask({
    required String bookingId,
    required String partyA,
    required String partyB,
  });
}

/// Demo DID. Not a customer or mechanic mobile.
const kMaskedDialNumber = '+911140004444';
