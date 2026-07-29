import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../models/booking_model.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── HISTORY SCREEN ───────────────────────────────────────────────────────────

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
      ref.read(bookingProvider.notifier).loadBookings('usr_001');
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(BookingStatus s) {
    if (s == BookingStatus.completed) return AppColors.success;
    if (s == BookingStatus.cancelled) return AppColors.error;
    return AppColors.primaryRed;
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.mechanicAssigned:
        return 'Assigned';
      case BookingStatus.pickedUp:
        return 'Picked Up';
      case BookingStatus.inWorkshop:
        return 'At Workshop';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.qualityCheck:
        return 'Quality Check';
      case BookingStatus.outForDelivery:
        return 'Out For Delivery';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service History'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const ShimmerList(count: 5),
        error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.read(bookingProvider.notifier).loadBookings('usr_001')),
        data: (bookings) {
          final all = bookings;
          final active = bookings.where((b) => b.isActive).toList();
          final completed = bookings
              .where((b) => b.status == BookingStatus.completed)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _BookingList(
                  bookings: all,
                  statusColor: _statusColor,
                  statusLabel: _statusLabel),
              _BookingList(
                  bookings: active,
                  statusColor: _statusColor,
                  statusLabel: _statusLabel),
              _BookingList(
                  bookings: completed,
                  statusColor: _statusColor,
                  statusLabel: _statusLabel),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Color Function(BookingStatus) statusColor;
  final String Function(BookingStatus) statusLabel;

  const _BookingList({
    required this.bookings,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No Bookings',
        subtitle: 'Your service history will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        final color = statusColor(b.status);
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
                          Text(b.serviceName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(b.bikeName,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    StatusBadge(
                        label: statusLabel(b.status), color: color),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoPill(Icons.calendar_today_outlined,
                        DateFormat('d MMM y').format(b.scheduledDate)),
                    const SizedBox(width: 8),
                    _InfoPill(Icons.access_time_rounded, b.scheduledTime),
                    const Spacer(),
                    Text(
                      '₹${b.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (b.isActive) ...[
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
                              extra: b.id),
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
                              extra: b.id),
                        ),
                      ),
                    ],
                  ),
                ],
                if (b.status == BookingStatus.completed) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Invoice',
                          height: 36,
                          icon: Icons.receipt_rounded,
                          onPressed: () => context.push(
                              RouteNames.invoice,
                              extra: b.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Inspection',
                          height: 36,
                          isOutlined: true,
                          onPressed: () => context.push(
                              RouteNames.inspection,
                              extra: b.id),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ─── SERVICE DETAIL SCREEN ────────────────────────────────────────────────────

class ServiceDetailScreen extends ConsumerWidget {
  final String bookingId;
  const ServiceDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingProvider);
    final booking = bookings.whenOrNull(data: (list) {
      try {
        return list.firstWhere((b) => b.id == bookingId);
      } catch (_) {
        return mockBookings.first;
      }
    }) ??
        mockBookings.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Details'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.bikeCardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.3)),
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
                          Text(booking.serviceName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(booking.bikeName,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                      StatusBadge(
                        label: booking.status == BookingStatus.completed
                            ? 'Completed'
                            : 'Cancelled',
                        color: booking.status == BookingStatus.completed
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                        DateFormat('d MMMM y')
                            .format(booking.scheduledDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(booking.scheduledTime,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Breakdown',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _Row2('Service Charge',
                      '₹${booking.servicePrice.toInt()}'),
                  if (booking.pickupCharges > 0)
                    _Row2('Pickup & Drop',
                        '₹${booking.pickupCharges.toInt()}'),
                  if (booking.discount > 0)
                    _Row2('Discount',
                        '-₹${booking.discount.toStringAsFixed(0)}',
                        color: AppColors.success),
                  _Row2('GST (18%)', '₹${booking.gst.toStringAsFixed(0)}',
                      color: AppColors.textSecondary),
                  const Divider(color: AppColors.divider, height: 20),
                  _Row2('Total',
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      bold: true),
                  _Row2('Payment Method', booking.paymentMethod),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mechanic
            if (booking.mechanicName != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryRed,
                        child: Icon(Icons.person,
                            color: Colors.white, size: 24)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.mechanicName!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('⭐ ${booking.mechanicRating} • Expert Mechanic',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action buttons
            if (booking.status == BookingStatus.completed) ...[
              AppButton(
                label: 'View Invoice',
                icon: Icons.receipt_long_rounded,
                onPressed: () =>
                    context.push(RouteNames.invoice, extra: booking.id),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'View Inspection Report',
                isOutlined: true,
                icon: Icons.camera_alt_rounded,
                onPressed: () =>
                    context.push(RouteNames.inspection, extra: booking.id),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Book Again',
                isOutlined: true,
                icon: Icons.repeat_rounded,
                onPressed: () => context.push(RouteNames.booking),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _Row2(String label, String value,
    {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    ),
  );
}
