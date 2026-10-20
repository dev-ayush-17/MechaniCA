import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking_model.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_states.dart';
import '../../widgets/shared/app_widgets.dart';
import '../booking/domain/booking.dart';
import '../booking/domain/repeat_prefill.dart';
import '../home/domain/booking_buckets.dart';
import '../home/domain/home_copy.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeBookingsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(BookingStatus s) {
    if (s == BookingStatus.completed || s == BookingStatus.paid) {
      return AppColors.success;
    }
    if (s == BookingStatus.cancelled || s == BookingStatus.failed) {
      return AppColors.error;
    }
    return AppColors.primaryRed;
  }

  Future<void> _refresh() => ref.read(homeBookingsProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(homeBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service History'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const ShimmerList(count: 5),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: _refresh),
        data: (bookings) {
          final upcoming = bookings.where(isUpcomingBooking).toList();
          final active = bookings.where(isInProgressBooking).toList();
          final past = bookings.where(isPastBooking).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _BookingList(
                bookings: upcoming,
                statusColor: _statusColor,
                onRefresh: _refresh,
              ),
              _BookingList(
                bookings: active,
                statusColor: _statusColor,
                onRefresh: _refresh,
              ),
              _BookingList(
                bookings: past,
                statusColor: _statusColor,
                onRefresh: _refresh,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.statusColor,
    required this.onRefresh,
  });

  final List<Booking> bookings;
  final Color Function(BookingStatus) statusColor;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primaryRed,
        backgroundColor: AppColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(
              icon: Icons.history_rounded,
              title: kNoServicesYet,
              subtitle: 'Your service history will appear here',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          final color = statusColor(b.status);
          final when = b.scheduledStart;
          return GestureDetector(
            onTap: () => context.push(RouteNames.serviceDetail, extra: b.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
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
                            Text(
                              b.serviceName.isEmpty ? b.serviceCode : b.serviceName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.displayNumber,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(label: b.status.label, color: color),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (when != null)
                        _InfoPill(
                          Icons.calendar_today_outlined,
                          DateFormat('d MMM y').format(when),
                        ),
                      const Spacer(),
                      Text(
                        '₹${(b.totalPaise / 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (isInProgressBooking(b)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Track',
                            height: 36,
                            icon: Icons.location_on_rounded,
                            onPressed: () => context.push(
                              RouteNames.liveTracking,
                              extra: b.id,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: 'Details',
                            height: 36,
                            isOutlined: true,
                            onPressed: () => context.push(
                              RouteNames.bookingDetails,
                              extra: b.id,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (b.status == BookingStatus.paid) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Book again',
                      height: 36,
                      isOutlined: true,
                      icon: Icons.repeat_rounded,
                      onPressed: () => context.push(
                        RouteNames.booking,
                        extra: RepeatPrefill.fromBooking(b),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(homeBookingsProvider);
    final booking = bookings.whenOrNull(data: (list) {
      for (final item in list) {
        if (item.id == bookingId) return item;
      }
      return null;
    });

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Service Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyState(
          icon: Icons.history_rounded,
          title: kNoServicesYet,
          subtitle: 'This booking is not on your list yet.',
        ),
      );
    }

    final when = booking.scheduledStart ?? DateTime.now();
    final paid = booking.status == BookingStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.bikeCardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                ),
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
                          Text(
                            booking.serviceName.isEmpty
                                ? booking.serviceCode
                                : booking.serviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            booking.displayNumber,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: booking.status.label,
                        color: paid ? AppColors.success : AppColors.primaryRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMMM y').format(when),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row2(
                    'Total',
                    '₹${(booking.totalPaise / 100).toStringAsFixed(0)}',
                    bold: true,
                  ),
                  if (booking.paymentMethod.isNotEmpty)
                    _row2('Payment Method', booking.paymentMethod),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (paid) ...[
              AppButton(
                label: 'Book Again',
                isOutlined: true,
                icon: Icons.repeat_rounded,
                onPressed: () => context.push(
                  RouteNames.booking,
                  extra: RepeatPrefill.fromBooking(booking),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _row2(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
