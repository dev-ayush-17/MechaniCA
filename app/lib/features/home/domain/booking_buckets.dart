import '../../../models/booking_model.dart';
import '../../booking/domain/booking.dart';

bool isInProgressBooking(Booking booking) {
  return switch (booking.status) {
    BookingStatus.mechanicAssigned ||
    BookingStatus.enRoute ||
    BookingStatus.arrived ||
    BookingStatus.inService =>
      true,
    _ => false,
  };
}

bool isUpcomingBooking(Booking booking) {
  return booking.status == BookingStatus.requested ||
      booking.status == BookingStatus.confirmed;
}

bool isPastBooking(Booking booking) => !booking.status.isOpen;

List<Booking> lastThreeServices(List<Booking> bookings) {
  final past = bookings.where(isPastBooking).toList()
    ..sort((a, b) {
      final aAt = a.scheduledStart ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.scheduledStart ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
  return past.take(3).toList();
}
