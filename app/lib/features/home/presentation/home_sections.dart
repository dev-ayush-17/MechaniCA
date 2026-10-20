import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../navigation/route_names.dart';
import '../../../widgets/shared/app_states.dart';
import '../../booking/domain/booking.dart';
import '../../health/domain/vehicle_health.dart';
import '../../vehicles/domain/vehicle.dart';
import '../domain/home_copy.dart';

class HomeBannerSlider extends StatelessWidget {
  const HomeBannerSlider({
    super.key,
    required this.banners,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<Map<String, String?>> banners;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          options: CarouselOptions(
            height: 160,
            viewportFraction: 0.9,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            onPageChanged: (i, _) => onChanged(i),
          ),
          itemBuilder: (_, i, __) {
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A0A0A), Color(0xFF1A0505)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppColors.primaryRed.withValues(alpha: 0.2), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b['title']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 8),
                        Text(b['sub']!, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        const Spacer(),
                        if (b['code'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Code: ${b['code']}', style: const TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: TextButton(
                      onPressed: () => context.push(RouteNames.booking),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: currentIndex,
          count: banners.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppColors.primaryRed,
            dotColor: AppColors.divider,
            dotHeight: 6,
            dotWidth: 6,
          ),
        ),
      ],
    );
  }
}

class HomeBikeCard extends StatelessWidget {
  const HomeBikeCard({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final name = vehicle?.displayName ?? 'Add a vehicle';
    final plate = vehicle?.registrationNumber ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => vehicle == null
            ? context.push(RouteNames.addBike)
            : context.push(RouteNames.bikeDetails, extra: vehicle!.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.bikeCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Bike', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        if (plate.isNotEmpty)
                          Text(plate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.motorcycle, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction2('Book\nService', Icons.calendar_today_outlined, () => context.push(RouteNames.booking)),
                  _QuickAction2('Emergency', Icons.sos_outlined, () => context.push(RouteNames.emergency)),
                  _QuickAction2('Offers', Icons.local_offer_outlined, () => context.push(RouteNames.offers)),
                  _QuickAction2('Pick & Drop', Icons.local_shipping_outlined, () => context.push(RouteNames.booking)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction2 extends StatelessWidget {
  const _QuickAction2(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryRed),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, height: 1.3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class HomeServicesGrid extends StatelessWidget {
  HomeServicesGrid({super.key});

  final _items = [
    ('Quick\nService', Icons.build_rounded),
    ('Premium\nService', Icons.star_rounded),
    ('Washing', Icons.water_drop_rounded),
    ('Chain\nCleaning', Icons.link_rounded),
    ('Engine\nRepair', Icons.settings_rounded),
    ('Brake\nRepair', Icons.radio_button_checked),
    ('Clutch\nRepair', Icons.radio_button_unchecked),
    ('Battery', Icons.battery_charging_full_rounded),
    ('Tyre/\nPuncture', Icons.circle_outlined),
    ('Accessories', Icons.extension_rounded),
    ('Help', Icons.help_outline_rounded),
    ('Accident\nRepair', Icons.car_crash_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => context.push(RouteNames.booking),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$2, size: 22, color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 6),
                  Text(item.$1, style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeBookingCard extends StatelessWidget {
  const HomeBookingCard({
    super.key,
    required this.title,
    required this.booking,
    required this.vehicleLabel,
  });

  final String title;
  final Booking booking;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final when = booking.scheduledStart;
    final dateText = when == null
        ? booking.status.label
        : DateFormat('d MMM y').format(when.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: 'View All',
          onAction: () => context.go(RouteNames.history),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => context.push(RouteNames.liveTracking, extra: booking.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceName.isEmpty ? booking.serviceCode : booking.serviceName,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(vehicleLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      StatusBadge(label: booking.status.label, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(dateText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(RouteNames.liveTracking, extra: booking.id),
                        child: const Text('Track Booking', style: TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class HomeEmptyBookingCard extends StatelessWidget {
  const HomeEmptyBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.booking),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: AppColors.primaryRed),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  kBookAService,
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeRecentServices extends StatelessWidget {
  const HomeRecentServices({super.key, required this.bookings, required this.vehicleLabel});

  final List<Booking> bookings;
  final String Function(Booking booking) vehicleLabel;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: kRecentServices, actionLabel: 'View All', onAction: () => context.go(RouteNames.history)),
        const SizedBox(height: 12),
        ...bookings.map((booking) {
          final when = booking.scheduledStart;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: () => context.push(RouteNames.serviceDetail, extra: booking.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceName.isEmpty ? booking.serviceCode : booking.serviceName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(vehicleLabel(booking), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      when == null ? booking.status.label : DateFormat('d MMM').format(when.toLocal()),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Booking', Icons.calendar_today_rounded, RouteNames.booking),
      ('Track', Icons.location_on_rounded, RouteNames.liveTracking),
      ('Wallet', Icons.account_balance_wallet_rounded, RouteNames.wallet),
      ('Offers', Icons.local_offer_rounded, RouteNames.offers),
      ('Refer', Icons.people_rounded, RouteNames.referEarn),
      ('Health', Icons.favorite_rounded, RouteNames.healthScore),
      ('Fuel', Icons.local_gas_station_rounded, RouteNames.fuelTracker),
      ('Docs', Icons.description_rounded, RouteNames.documents),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              return GestureDetector(
                onTap: () => context.push(a.$3),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Icon(a.$2, size: 22, color: AppColors.primaryRed),
                      ),
                      const SizedBox(height: 6),
                      Text(a.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HomeHealthScoreMini extends StatelessWidget {
  const HomeHealthScoreMini({super.key, required this.health});

  final VehicleHealth health;

  Color get _bandColor => switch (health.band) {
        HealthBand.good => AppColors.success,
        HealthBand.fair => AppColors.warning,
        HealthBand.poor => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.healthScore),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Health Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${health.score}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('/100', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _bandColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(health.label, style: TextStyle(color: _bandColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              kHealthFromLastService,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeFuelMini extends StatelessWidget {
  const HomeFuelMini({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.fuelTracker),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹1,250', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Total Spent', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('42 L', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Total Litres', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4),
            Text('Mileage: 45 km/L', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class HomeOffersList extends StatelessWidget {
  const HomeOffersList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _offerCard('FLAT 20% OFF', 'On Complete Service', 'ARC049', AppColors.primaryRed, context),
          _offerCard('₹110 OFF', 'On Bike Washing', 'WASH110', AppColors.info, context),
          _offerCard('Refer & Earn ₹150', 'Invite friends', null, AppColors.warning, context),
        ],
      ),
    );
  }

  Widget _offerCard(String title, String sub, String? code, Color color, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.offers),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            if (code != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Code: $code', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeOfflineBanner extends StatelessWidget {
  const HomeOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: const Text(
          kOfflineHomeBanner,
          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
