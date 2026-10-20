import '../../../core/error/result.dart';
import 'location_point.dart';

abstract interface class LocationTrackingService {
  Future<Result<void>> publish({
    required String bookingId,
    required String role,
    required LocationPoint point,
  });

  Future<Result<LocationSnapshot?>> latest(String bookingId);

  Stream<LocationSnapshot> watch(String bookingId);
}
