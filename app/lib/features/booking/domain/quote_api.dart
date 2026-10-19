import '../../../core/error/result.dart';
import '../../vehicles/domain/vehicle.dart';
import 'pricing.dart';

abstract class QuoteApi {
  Future<Result<PriceQuote>> quote({
    required String serviceCode,
    required String vehicleId,
    required VehicleType vehicleType,
    String couponCode,
  });
}
