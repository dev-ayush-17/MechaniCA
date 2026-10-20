import '../../../core/error/result.dart';
import '../domain/telephony_port.dart';

class FakeTelephony implements TelephonyPort {
  @override
  Future<Result<MaskedCall>> mask({
    required String bookingId,
    required String partyA,
    required String partyB,
  }) async {
    return Ok(
      MaskedCall(
        dialNumber: kMaskedDialNumber,
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );
  }
}
