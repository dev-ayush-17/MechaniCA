class CouponOffer {
  const CouponOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.amount,
    required this.maxDiscountPaise,
    required this.minLaborPaise,
    required this.endsAt,
  });

  final String code;
  final String title;
  final String description;
  final String type;
  final int amount;
  final int maxDiscountPaise;
  final int minLaborPaise;
  final DateTime endsAt;

  String get id => code;
  String get couponCode => code;
  DateTime get validTill => endsAt;
  int get discountPercent => type == 'percent' ? amount : 0;
  double get maxDiscount => maxDiscountPaise / 100;
  double get minOrderValue => minLaborPaise / 100;
  String get badgeText => type == 'percent' ? '$amount% OFF' : 'FLAT';
  String get category => 'service';
}

class CouponQuote {
  const CouponQuote({
    required this.code,
    required this.discountPaise,
    required this.message,
  });

  final String code;
  final int discountPaise;
  final String message;
}
