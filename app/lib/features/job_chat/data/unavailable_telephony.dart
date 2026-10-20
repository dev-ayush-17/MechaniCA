import '../../../core/error/result.dart';
import '../domain/telephony_port.dart';

/// Real-adapter stand-in until a vendor is contracted (FR-COM-002).
class UnavailableTelephony implements TelephonyPort {
  @override
  Future<Result<MaskedCall>> mask({
    required String bookingId,
    required String partyA,
    required String partyB,
  }) async {
    return const Err(Unavailable('Calling is unavailable. Use chat.'));
  }
}
