import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../../booking/domain/pricing.dart';
import '../../booking/domain/quote_api.dart';
import '../../vehicles/domain/vehicle.dart';
import 'catalog_local_store.dart';

class CachedQuoteApi implements QuoteApi {
  CachedQuoteApi({
    required QuoteApi remote,
    required CatalogLocalStore local,
    required bool Function() isOnline,
    required Clock clock,
  })  : _remote = remote,
        _local = local,
        _isOnline = isOnline,
        _clock = clock;

  final QuoteApi _remote;
  final CatalogLocalStore _local;
  final bool Function() _isOnline;
  final Clock _clock;

  @override
  Future<Result<PriceQuote>> quote({
    required String serviceCode,
    required String vehicleId,
    required VehicleType vehicleType,
    String couponCode = '',
  }) async {
    final key = '$serviceCode|${vehicleType.name}|$couponCode|$vehicleId';
    if (_isOnline()) {
      final remote = await _remote.quote(
        serviceCode: serviceCode,
        vehicleId: vehicleId,
        vehicleType: vehicleType,
        couponCode: couponCode,
      );
      return remote.when(
        onOk: (quote) async {
          await _local.saveQuote(key, quote, _clock.now());
          return Ok(quote);
        },
        onErr: (failure) async {
          final cached = await _local.loadQuote(key);
          if (cached != null) return Ok(cached);
          return Err(failure);
        },
      );
    }
    final cached = await _local.loadQuote(key);
    if (cached != null) return Ok(cached);
    return const Err(Unavailable('Quote is unavailable offline.'));
  }
}
