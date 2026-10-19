/// SOS create body. Dispatch timings stay normal until M07.
class SosBookingPayload {
  const SosBookingPayload({
    required this.urgency,
    required this.mode,
    required this.serviceCode,
    required this.reason,
  });

  final String urgency;
  final String mode;
  final String serviceCode;
  final String reason;

  bool get showEmergencyServicesCopy => reason == 'accident_safe';
}

SosBookingPayload sosPayloadFor(String emergencyType) {
  final reason = switch (emergencyType) {
    'SOS' || 'Breakdown' => 'breakdown',
    'Accident' => 'accident_safe',
    'Battery Dead' || 'Flat Tyre' || 'Fuel Empty' => 'wont_start',
    _ => 'other',
  };
  return SosBookingPayload(
    urgency: 'sos',
    mode: 'instant',
    serviceCode: 'breakdown',
    reason: reason,
  );
}
