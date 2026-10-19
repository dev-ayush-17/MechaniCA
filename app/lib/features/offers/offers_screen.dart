import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── OFFERS SCREEN ────────────────────────────────────────────────────────────

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Offers & Coupons'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
          bottom: const TabBar(tabs: [
            Tab(text: 'All Offers'),
            Tab(text: 'Coupons'),
            Tab(text: 'Membership'),
          ]),
        ),
        body: TabBarView(
          children: [
            // All Offers
            offersAsync.when(
              loading: () => const ShimmerList(),
              error: (_, __) => const ErrorState(message: 'Failed to load offers'),
              data: (offers) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (_, i) => _OfferCard(offer: offers[i])
                    .animate().fadeIn(delay: Duration(milliseconds: i * 80)),
              ),
            ),
            // Coupons
            offersAsync.when(
              loading: () => const ShimmerList(),
              error: (_, __) => const ErrorState(message: 'Failed to load coupons'),
              data: (offers) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (_, i) => _CouponCard(offer: offers[i]),
              ),
            ),
            // Membership Offers
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MemberCard('Gold Member', '6 months', '₹499', ['2 Free Services', '20% off', 'Free Pickup', 'Priority Support'], AppColors.gold, () => context.push(RouteNames.membership)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final dynamic offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.offerDetails, extra: offer.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(offer.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                StatusBadge(label: offer.badgeText, color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 6),
            Text(offer.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4), style: BorderStyle.solid)),
                  child: Text(offer.couponCode, style: const TextStyle(color: AppColors.primaryRed, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                const Spacer(),
                Text('Valid till ${offer.validTill.day}/${offer.validTill.month}/${offer.validTill.year}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final dynamic offer;
  const _CouponCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  offer.discountPercent > 0 ? '${offer.discountPercent}%' : '₹${offer.maxDiscount.toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Text('OFF', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.couponCode, style: const TextStyle(color: AppColors.primaryRed, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(offer.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Min: ₹${offer.minOrderValue.toInt()}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              label: 'Apply',
              height: 36,
              onPressed: () => showAppSnackbar(context, 'Code ${offer.couponCode} copied!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String plan;
  final String duration;
  final String price;
  final List<String> benefits;
  final Color color;
  final VoidCallback onTap;
  const _MemberCard(this.plan, this.duration, this.price, this.benefits, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), AppColors.cardBackground], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: color, size: 32),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$plan Member', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(duration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Text(price, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Text(b, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            )).toList(),
            const SizedBox(height: 16),
            AppButton(label: 'Upgrade Now', onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

// ─── OFFER DETAILS SCREEN ─────────────────────────────────────────────────────

class OfferDetailsScreen extends ConsumerWidget {
  final String offerId;
  const OfferDetailsScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);
    final offer = offersAsync.whenOrNull(data: (list) {
      try { return list.firstWhere((o) => o.id == offerId); }
      catch (_) { return mockOffers.first; }
    }) ?? mockOffers.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offer Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  Text(offer.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(offer.couponCode, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        GestureDetector(
                          onTap: () => showAppSnackbar(context, 'Code copied!'),
                          child: const Text('COPY', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _OfferInfoRow('Discount', offer.discountPercent > 0 ? '${offer.discountPercent}%' : '₹${offer.maxDiscount.toInt()}'),
            _OfferInfoRow('Min Order', '₹${offer.minOrderValue.toInt()}'),
            _OfferInfoRow('Max Discount', '₹${offer.maxDiscount.toInt()}'),
            _OfferInfoRow('Valid Till', '${offer.validTill.day}/${offer.validTill.month}/${offer.validTill.year}'),
            _OfferInfoRow('Category', offer.category.toUpperCase()),
            const SizedBox(height: 24),
            AppButton(
              label: 'Book Now & Apply',
              onPressed: () => context.push(RouteNames.booking),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _OfferInfoRow(String label, String value) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
