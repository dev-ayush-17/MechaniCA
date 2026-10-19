import '../../../core/error/result.dart';
import '../domain/coupon_api.dart';
import '../domain/coupon_offer.dart';

final _seed = <CouponOffer>[
  CouponOffer(
    code: 'FLAT50',
    title: 'Flat ₹50 off',
    description: '₹50 off labor',
    type: 'flat',
    amount: 5000,
    maxDiscountPaise: 5000,
    minLaborPaise: 0,
    endsAt: DateTime.utc(2027, 1, 1),
  ),
  CouponOffer(
    code: 'ONCE',
    title: 'One redeem',
    description: 'Single use',
    type: 'flat',
    amount: 1000,
    maxDiscountPaise: 1000,
    minLaborPaise: 0,
    endsAt: DateTime.utc(2027, 1, 1),
  ),
  CouponOffer(
    code: 'MIN299',
    title: '10% off',
    description: 'Min labor ₹299',
    type: 'percent',
    amount: 10,
    maxDiscountPaise: 10000,
    minLaborPaise: 29900,
    endsAt: DateTime.utc(2027, 1, 1),
  ),
];

class FakeCouponApi implements CouponApi {
  FakeCouponApi({List<CouponOffer>? items}) : items = items ?? List.of(_seed);

  final List<CouponOffer> items;

  @override
  Future<Result<List<CouponOffer>>> list() async => Ok(items);

  @override
  Future<Result<CouponQuote>> validate({
    required String code,
    required int laborPaise,
  }) async {
    final upper = code.trim().toUpperCase();
    if (upper == 'EXPIRED') {
      return const Err(InvalidInput('Code expired'));
    }
    CouponOffer? match;
    for (final item in items) {
      if (item.code == upper) match = item;
    }
    if (match == null) {
      return const Err(InvalidInput('Invalid coupon code'));
    }
    if (laborPaise < match.minLaborPaise) {
      return Err(InvalidInput('Minimum labor is ₹${match.minLaborPaise ~/ 100}'));
    }
    final raw = match.type == 'percent'
        ? laborPaise * match.amount ~/ 100
        : match.amount;
    final discount = raw > match.maxDiscountPaise ? match.maxDiscountPaise : raw;
    return Ok(
      CouponQuote(
        code: match.code,
        discountPaise: discount > laborPaise ? laborPaise : discount,
        message: 'Coupon applied.',
      ),
    );
  }
}
