import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/booking/domain/sos_payload.dart';

void main() {
  test('sos_sets_urgency', () {
    final payload = sosPayloadFor('SOS');
    expect(payload.urgency, 'sos');
    expect(payload.mode, 'instant');
    expect(payload.serviceCode, 'breakdown');
    expect(payload.reason, 'breakdown');
  });

  test('accident_safe_asks_to_call_112', () {
    final payload = sosPayloadFor('Accident');
    expect(payload.reason, 'accident_safe');
    expect(payload.showEmergencyServicesCopy, isTrue);
    expect(payload.urgency, 'sos');
  });
}
