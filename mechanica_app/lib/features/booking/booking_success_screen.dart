import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../widgets/shared/app_widgets.dart';

class BookingSuccessScreen extends ConsumerWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingProvider);
    final booking = bookings.whenOrNull(data: (list) {
      try { return list.firstWhere((b) => b.id == bookingId); }
      catch (_) { return mockBookings.first; }
    }) ?? mockBookings.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Success animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, size: 60, color: AppColors.success),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              const Text('Your bike has been successfully booked.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),
              // Booking details card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _InfoRow('Booking ID', booking.bookingNumber),
                    _InfoRow('Service', booking.serviceName),
                    _InfoRow('Bike', booking.bikeName),
                    _InfoRow('Scheduled', '${booking.scheduledDate.day} May 2024 at ${booking.scheduledTime}'),
                    _InfoRow('Amount', '₹${booking.totalAmount.toStringAsFixed(0)}'),
                    _InfoRow('Payment', booking.paymentMethod),
                  ],
                ),
              ).animate().slideY(begin: 0.2, delay: 500.ms),

              const Spacer(),

              AppButton(
                label: 'Track Booking',
                icon: Icons.location_on_rounded,
                onPressed: () => context.pushReplacement(RouteNames.liveTracking, extra: booking.id),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Home',
                isOutlined: true,
                onPressed: () => context.go(RouteNames.home),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _InfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
