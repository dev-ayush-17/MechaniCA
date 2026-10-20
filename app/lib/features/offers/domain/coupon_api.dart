import '../../../core/error/result.dart';
import 'coupon_offer.dart';

/// FastAPI coupon catalog. Validate does not redeem.
abstract class CouponApi {
  Future<Result<List<CouponOffer>>> list();

  Future<Result<CouponQuote>> validate({
    required String code,
    required int laborPaise,
  });
}
