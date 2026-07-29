import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../widgets/shared/app_states.dart';
import '../../widgets/shared/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bannerIndex = 0;
  bool _isRefreshing = false;

  final _banners = [
    {'title': 'FLAT 20% OFF', 'sub': 'ON COMPLETE SERVICE\nThis Week Only!', 'code': 'FLAT20'},
    {'title': '₹110 OFF', 'sub': 'ON BIKE WASHING\nUse code WASH110', 'code': 'WASH110'},
    {'title': 'GOLD MEMBER', 'sub': 'Upgrade & Save More\nFree Pickup & Drop', 'code': null},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  void _load() {
    final userId = mockUser.id;
    ref.read(bookingProvider.notifier).loadBookings(userId);
    ref.read(notificationProvider.notifier).load(userId);
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    _load();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingProvider);
    final unread = ref.watch(notificationProvider).whenOrNull(
              data: (list) => list.where((n) => !n.isRead).length,
            ) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryRed,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppColors.background,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.build_circle_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good Morning,', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
                      Text(mockUser.name.split(' ').first + ' 👋',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primaryRed),
                      const SizedBox(width: 2),
                      const Text('Patna, Bihar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push(RouteNames.notifications),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Slider
                  _BannerSlider(
                    banners: _banners,
                    currentIndex: _bannerIndex,
                    onChanged: (i) => setState(() => _bannerIndex = i),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  // My Bike Card
                  _MyBikeCard(),

                  const SizedBox(height: 20),

                  // Quick Services
                  SectionHeader(
                    title: 'Services',
                    actionLabel: 'View All',
                    onAction: () => context.push(RouteNames.booking),
                  ),
                  const SizedBox(height: 12),
                  _ServicesGrid(),

                  const SizedBox(height: 20),

                  // Active Booking
                  bookingsAsync.when(
                    loading: () => const ShimmerCard(height: 100),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (bookings) {
                      final active = bookings.where((b) => b.isActive).toList();
                      if (active.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Upcoming Booking',
                            actionLabel: 'View All',
                            onAction: () => context.go(RouteNames.history),
                          ),
                          const SizedBox(height: 12),
                          _ActiveBookingCard(booking: active.first),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                  // Quick Actions Row
                  _QuickActions(),

                  const SizedBox(height: 20),

                  // Health Score & Fuel Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _HealthScoreMini()),
                        const SizedBox(width: 12),
                        Expanded(child: _FuelMini()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Offers
                  SectionHeader(
                    title: 'Offers & Coupons',
                    actionLabel: 'View All',
                    onAction: () => context.push(RouteNames.offers),
                  ),
                  const SizedBox(height: 12),
                  _OffersList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      // Emergency FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.emergency),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.sos, color: Colors.white),
        label: const Text('Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        elevation: 8,
      ),
    );
  }
}

// ─── BANNER SLIDER ────────────────────────────────────────────────────────────

class _BannerSlider extends StatelessWidget {
  final List<Map<String, String?>> banners;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BannerSlider({
    required this.banners,
    required this.currentIndex,
    required this.onChanged,
  });

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
                    padding: const EdgeInsets.all(20),
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
                      onPressed: () {},
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

// ─── MY BIKE CARD ─────────────────────────────────────────────────────────────

class _MyBikeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bike = mockBikes.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.bikeDetails, extra: bike.id),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Bike', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(bike.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(bike.registrationNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
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
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction2(this.label, this.icon, this.onTap);

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

// ─── SERVICES GRID ────────────────────────────────────────────────────────────

class _ServicesGrid extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

// ─── ACTIVE BOOKING CARD ─────────────────────────────────────────────────────

class _ActiveBookingCard extends StatelessWidget {
  final dynamic booking;
  const _ActiveBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.serviceName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(booking.bikeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  StatusBadge(label: 'Live in 5 Min', color: AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.scheduledDate.day} May 2024  •  ${booking.scheduledTime}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
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
    );
  }
}

// ─── QUICK ACTIONS ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
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

// ─── HEALTH SCORE MINI ────────────────────────────────────────────────────────

class _HealthScoreMini extends StatelessWidget {
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
                const Text('85', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('/100', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Good', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Your Bike is in Good Condition', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── FUEL MINI ────────────────────────────────────────────────────────────────

class _FuelMini extends StatelessWidget {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            const Row(
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
            const SizedBox(height: 4),
            const Text('Mileage: 45 km/L', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── OFFERS LIST ──────────────────────────────────────────────────────────────

class _OffersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _OfferCard('FLAT 20% OFF', 'On Complete Service', 'ARC049', AppColors.primaryRed, context),
          _OfferCard('₹110 OFF', 'On Bike Washing', 'WASH110', AppColors.info, context),
          _OfferCard('Refer & Earn ₹150', 'Invite friends', null, AppColors.warning, context),
        ],
      ),
    );
  }

  Widget _OfferCard(String title, String sub, String? code, Color color, BuildContext context) {
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
