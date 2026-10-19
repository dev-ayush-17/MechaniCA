import '../../../core/error/result.dart';
import '../../booking/domain/pricing.dart';
import '../../booking/domain/quote_api.dart';
import '../../vehicles/domain/vehicle.dart';
import '../domain/catalog_repository.dart';

class FakeQuoteApi implements QuoteApi {
  FakeQuoteApi({
    required CatalogRepository catalog,
    this.pricing = const PricingService(),
  }) : _catalog = catalog;

  final CatalogRepository _catalog;
  final PricingService pricing;

  @override
  Future<Result<PriceQuote>> quote({
    required String serviceCode,
    required String vehicleId,
    required VehicleType vehicleType,
    String couponCode = '',
  }) async {
    if (couponCode.trim().isNotEmpty) {
      return const Err(InvalidInput('Coupons arrive in M10.'));
    }
    final loaded = await _catalog.getService(serviceCode);
    return loaded.when(
      onOk: (service) {
        if (service == null) {
          return const Err(NotFound('We could not find that service.'));
        }
        return pricing.quote(
          QuoteInput(service: service, vehicleType: vehicleType),
        );
      },
      onErr: Err.new,
    );
  }
}
