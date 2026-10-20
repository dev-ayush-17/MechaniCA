import '../../../core/error/result.dart';
import 'booking.dart';

abstract class BookingApi {
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
  });

  Future<Result<Booking>> cancel(String bookingId, {required String reason});

  Future<Result<List<Booking>>> listMine();
}
