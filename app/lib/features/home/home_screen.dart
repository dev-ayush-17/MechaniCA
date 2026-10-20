import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/presentation/push_denied_banner.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_states.dart';
import '../booking/domain/booking.dart';
import '../health/domain/vehicle_health.dart';
import '../vehicles/domain/vehicle.dart';
import 'domain/booking_buckets.dart';
import 'domain/home_copy.dart';
import 'presentation/home_sections.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bannerIndex = 0;

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
      final pending = ref.read(pendingDeepLinkProvider).consume(DateTime.now());
      if (pending != null && mounted) context.go(pending);
    });
  }

  void _load() {
    final userId = ref.read(authProvider).session?.userId;
    ref.read(homeBookingsProvider.notifier).load();
    ref.read(notificationsControllerProvider.notifier).load();
    if (userId != null) {
      ref.read(vehiclesControllerProvider.notifier).load(userId);
    }
  }

  Future<void> _refresh() async {
    _load();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  String _vehicleLabel(Booking booking, List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.id == booking.vehicleId) return vehicle.displayName;
    }
    return booking.vehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(homeBookingsProvider);
    final vehicles = ref.watch(vehiclesControllerProvider).vehicles;
    final online = ref.watch(networkOnlineProvider);
    final accountName = ref.watch(authProvider).account?.name.trim() ?? '';
    final firstName = accountName.isEmpty ? 'there' : accountName.split(' ').first;
    final unread = ref.watch(notificationsControllerProvider).whenOrNull(
              data: (list) => list.where((n) => !n.isRead).length,
            ) ??
        0;
    Vehicle? primary;
    for (final vehicle in vehicles) {
      if (vehicle.isPrimary) {
        primary = vehicle;
        break;
      }
    }
    primary ??= vehicles.isEmpty ? null : vehicles.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryRed,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
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
                      Text('$firstName 👋',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ],
              ),
              actions: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppColors.primaryRed),
                      SizedBox(width: 2),
                      Text('Patna, Bihar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const HomePushDeniedBanner(),
                  if (!online) const HomeOfflineBanner(),
                  HomeBannerSlider(
                    banners: _banners,
                    currentIndex: _bannerIndex,
                    onChanged: (i) => setState(() => _bannerIndex = i),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  HomeBikeCard(vehicle: primary),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Services',
                    actionLabel: 'View All',
                    onAction: () => context.push(RouteNames.booking),
                  ),
                  const SizedBox(height: 12),
                  HomeServicesGrid(),
                  const SizedBox(height: 20),
                  bookingsAsync.when(
                    loading: () => const ShimmerCard(height: 100),
                    error: (_, __) => const HomeEmptyBookingCard(),
                    data: (bookings) {
                      final active = bookings.where(isInProgressBooking).toList();
                      final upcoming = bookings.where(isUpcomingBooking).toList();
                      final recent = lastThreeServices(bookings);
                      return Column(
                        children: [
                          if (active.isEmpty)
                            const HomeEmptyBookingCard()
                          else
                            HomeBookingCard(
                              title: kUpcomingBooking,
                              booking: active.first,
                              vehicleLabel: _vehicleLabel(active.first, vehicles),
                            ),
                          if (upcoming.isNotEmpty)
                            HomeBookingCard(
                              title: kNextScheduled,
                              booking: upcoming.first,
                              vehicleLabel: _vehicleLabel(upcoming.first, vehicles),
                            ),
                          HomeRecentServices(
                            bookings: recent,
                            vehicleLabel: (booking) => _vehicleLabel(booking, vehicles),
                          ),
                        ],
                      );
                    },
                  ),
                  const HomeQuickActions(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: HomeHealthScoreMini(
                            health: healthFromLastService(
                              lastCompletedServiceAt(
                                bookingsAsync.valueOrNull ?? const [],
                              ),
                              now: DateTime.now(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: HomeFuelMini()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Offers & Coupons',
                    actionLabel: 'View All',
                    onAction: () => context.push(RouteNames.offers),
                  ),
                  const SizedBox(height: 12),
                  const HomeOffersList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
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
