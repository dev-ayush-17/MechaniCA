import '../../../core/error/result.dart';
import '../../../models/booking_model.dart';
import '../domain/booking.dart';
import '../domain/booking_api.dart';

class FakeBookingApi implements BookingApi {
  FakeBookingApi({this.failCreateWith, List<Booking>? seed, this.getDelay})
      : seeded = [...?seed];

  final AppFailure? failCreateWith;
  final Duration? getDelay;
  final List<Booking> created = [];
  final List<String> cancelled = [];
  final List<Booking> seeded;
  int getCalls = 0;
  int inFlightGets = 0;
  int maxInFlightGets = 0;

  @override
  Future<Result<Booking>> create({
    required String vehicleId,
    required String serviceCode,
    required String addressId,
    required String paymentMethod,
    required String mode,
    required String urgency,
    required String idempotencyKey,
    DateTime? scheduledStart,
    String couponCode = '',
  }) async {
    if (failCreateWith != null) return Err(failCreateWith!);
    final existing = created.cast<Booking?>().firstWhere(
          (item) => item?.id == idempotencyKey,
          orElse: () => null,
        );
    if (existing != null) return Ok(existing);
    final booking = Booking(
      id: idempotencyKey,
      displayNumber: 'MC${idempotencyKey.replaceAll('-', '').substring(0, 8).toUpperCase()}',
      status: BookingStatus.confirmed,
      serviceCode: urgency == 'sos' ? 'breakdown' : serviceCode,
      mode: urgency == 'sos' ? 'instant' : mode,
      urgency: urgency,
      totalPaise: 76464,
      cancelFeePaise: 0,
      version: 1,
    );
    created.add(booking);
    return Ok(booking);
  }

  @override
  Future<Result<Booking>> cancel(String bookingId, {required String reason}) async {
    cancelled.add('$bookingId:$reason');
    final match = created.cast<Booking?>().firstWhere(
          (item) => item?.id == bookingId,
          orElse: () => null,
        );
    final booking = match ??
        Booking(
          id: bookingId,
          displayNumber: 'MC${bookingId.substring(0, 8).toUpperCase()}',
          status: BookingStatus.cancelled,
          serviceCode: 'general_service',
          mode: 'instant',
          urgency: 'normal',
          totalPaise: 0,
          cancelFeePaise: 0,
          version: 2,
        );
    return Ok(booking);
  }

  final openedDisputes = <String>[];

  @override
  Future<Result<void>> openDispute(String bookingId, {required String reason}) async {
    openedDisputes.add('$bookingId:$reason');
    return const Ok(null);
  }

  @override
  Future<Result<List<Booking>>> listMine() async {
    return Ok([...seeded, ...created]);
  }

  @override
  Future<Result<Booking>> get(String bookingId) async {
    getCalls += 1;
    inFlightGets += 1;
    if (inFlightGets > maxInFlightGets) maxInFlightGets = inFlightGets;
    final delay = getDelay;
    if (delay != null) await Future<void>.delayed(delay);
    inFlightGets -= 1;
    for (final item in [...seeded, ...created]) {
      if (item.id == bookingId) return Ok(item);
    }
    return const Err(NotFound('We could not find that booking.'));
  }
}
