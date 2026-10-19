import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../models/booking_model.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingProvider);
    final booking = bookings.whenOrNull(data: (list) {
      try { return list.firstWhere((b) => b.id == bookingId); }
      catch (_) { return mockBookings.first; }
    }) ?? mockBookings.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          if (booking.isActive)
            TextButton(
              onPressed: () => _showCancelSheet(context, ref, booking),
              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.bikeCardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.serviceName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(booking.bikeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        StatusBadge(label: _statusLabel(booking.status), color: _statusColor(booking.status)),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.build_rounded, color: AppColors.primaryRed, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Details
            _InfoCard('Booking Info', [
              _DetailRow('Booking ID', booking.bookingNumber),
              _DetailRow('Date', DateFormat('dd MMM yyyy').format(booking.scheduledDate)),
              _DetailRow('Time', booking.scheduledTime),
              _DetailRow('Type', booking.serviceType == ServiceType.pickupDrop ? 'Pickup & Drop' : 'Visit Workshop'),
              if (booking.pickupAddress != null) _DetailRow('Address', booking.pickupAddress!),
            ]),
            const SizedBox(height: 12),
            _InfoCard('Payment Info', [
              _DetailRow('Service', '₹${booking.servicePrice.toInt()}'),
              if (booking.pickupCharges > 0) _DetailRow('Pickup Charges', '₹${booking.pickupCharges.toInt()}'),
              if (booking.discount > 0) _DetailRow('Discount', '-₹${booking.discount.toStringAsFixed(0)}', color: AppColors.success),
              _DetailRow('GST', '₹${booking.gst.toStringAsFixed(0)}'),
              _DetailRow('Total', '₹${booking.totalAmount.toStringAsFixed(0)}', bold: true),
              _DetailRow('Payment', booking.paymentMethod),
            ]),

            if (booking.mechanicName != null) ...[
              const SizedBox(height: 12),
              _InfoCard('Mechanic Details', [
                _DetailRow('Name', booking.mechanicName!),
                _DetailRow('Rating', '⭐ ${booking.mechanicRating}'),
                _DetailRow('Phone', booking.mechanicPhone ?? 'N/A'),
              ]),
            ],

            const SizedBox(height: 20),
            if (booking.isActive) ...[
              AppButton(
                label: 'Track Live',
                icon: Icons.location_on_rounded,
                onPressed: () => context.push(RouteNames.liveTracking, extra: booking.id),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Reschedule',
                isOutlined: true,
                icon: Icons.schedule_rounded,
                onPressed: () => context.push(RouteNames.reschedule, extra: booking.id),
              ),
            ],
            if (booking.status == BookingStatus.completed) ...[
              AppButton(
                label: 'View Invoice',
                icon: Icons.receipt_long_rounded,
                onPressed: () => context.push(RouteNames.invoice, extra: booking.id),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'View Inspection',
                isOutlined: true,
                onPressed: () => context.push(RouteNames.inspection, extra: booking.id),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showCancelSheet(BuildContext context, WidgetRef ref, BookingModel booking) {
    String? reason;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancel Booking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Are you sure you want to cancel?', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ...['Changed my plans', 'Found better price', 'Emergency', 'Other'].map((r) =>
                GestureDetector(
                  onTap: () => setState(() => reason = r),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: reason == r ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: reason == r ? AppColors.primaryRed : AppColors.divider),
                    ),
                    child: Row(children: [
                      Icon(reason == r ? Icons.radio_button_checked : Icons.radio_button_off, color: reason == r ? AppColors.primaryRed : AppColors.textTertiary, size: 18),
                      const SizedBox(width: 10),
                      Text(r, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ]),
                  ),
                ),
              ).toList(),
              const SizedBox(height: 16),
              AppButton(
                label: 'Confirm Cancel',
                color: AppColors.error,
                onPressed: reason == null ? null : () {
                  ref.read(bookingProvider.notifier).cancelBooking(booking.id, reason!);
                  Navigator.pop(ctx);
                  context.pop();
                  showAppSnackbar(context, 'Booking cancelled successfully');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.mechanicAssigned: return 'Mechanic Assigned';
      case BookingStatus.pickedUp: return 'Bike Picked Up';
      case BookingStatus.inWorkshop: return 'At Workshop';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.qualityCheck: return 'Quality Check';
      case BookingStatus.outForDelivery: return 'Out for Delivery';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.rescheduled: return 'Rescheduled';
      default: return 'Pending';
    }
  }

  Color _statusColor(BookingStatus s) {
    if (s == BookingStatus.completed) return AppColors.success;
    if (s == BookingStatus.cancelled) return AppColors.error;
    return AppColors.primaryRed;
  }
}

Widget _InfoCard(String title, List<Widget> rows) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...rows,
      ],
    ),
  );
}

Widget _DetailRow(String label, String value, {Color? color, bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    ),
  );
}

// ─── RESCHEDULE SCREEN ────────────────────────────────────────────────────────

class RescheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const RescheduleScreen({super.key, required this.bookingId});
  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 2));
  String? _time;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reschedule Booking')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Date', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (_, child) => Theme(data: ThemeData.dark(), child: child!),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: 12),
                    Text('${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month-1]} ${_date.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('New Time', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '4:00 PM'].map((t) {
              final sel = _time == t;
              return GestureDetector(
                onTap: () => setState(() => _time = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryRed : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primaryRed : AppColors.divider),
                  ),
                  child: Text(t, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                ),
              );
            }).toList()),
            const Spacer(),
            AppButton(
              label: 'Confirm Reschedule',
              isLoading: _isLoading,
              onPressed: _time == null ? null : () async {
                setState(() => _isLoading = true);
                await ref.read(bookingRepositoryProvider).rescheduleBooking(widget.bookingId, _date, _time!);
                if (mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, 'Booking rescheduled successfully!');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
