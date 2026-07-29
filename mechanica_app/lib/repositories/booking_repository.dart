import '../models/booking_model.dart';
import '../mock/mock_data.dart';
import '../mock/mock_delay.dart';

abstract class BookingRepository {
  Future<List<BookingModel>> getBookings(String userId);
  Future<BookingModel> getBookingById(String bookingId);
  Future<BookingModel> createBooking(BookingModel booking);
  Future<BookingModel> updateBookingStatus(String bookingId, BookingStatus status);
  Future<void> cancelBooking(String bookingId, String reason);
  Future<BookingModel> rescheduleBooking(String bookingId, DateTime newDate, String newTime);
  Future<BookingModel> rateBooking(String bookingId, int rating, String review);
}

class MockBookingRepository implements BookingRepository {
  final List<BookingModel> _bookings = List.from(mockBookings);

  @override
  Future<List<BookingModel>> getBookings(String userId) async {
    await MockDelay.wait();
    return _bookings.where((b) => b.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) async {
    await MockDelay.short();
    return _bookings.firstWhere((b) => b.id == bookingId);
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    await MockDelay.long();
    _bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<BookingModel> updateBookingStatus(String bookingId, BookingStatus status) async {
    await MockDelay.short();
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      return _bookings[index];
    }
    throw Exception('Booking not found');
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    await MockDelay.wait();
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.cancelled,
        cancellationReason: reason,
      );
    }
  }

  @override
  Future<BookingModel> rescheduleBooking(String bookingId, DateTime newDate, String newTime) async {
    await MockDelay.wait();
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        scheduledDate: newDate,
        scheduledTime: newTime,
        status: BookingStatus.rescheduled,
      );
      return _bookings[index];
    }
    throw Exception('Booking not found');
  }

  @override
  Future<BookingModel> rateBooking(String bookingId, int rating, String review) async {
    await MockDelay.wait();
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(rating: rating, review: review);
      return _bookings[index];
    }
    throw Exception('Booking not found');
  }
}
