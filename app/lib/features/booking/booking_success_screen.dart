import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_widgets.dart';
import 'domain/booking.dart';
import 'domain/pricing.dart';

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  final String bookingId;
  final Booking? booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final created = booking;
    final l10n = l10nOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 60,
                          color: AppColors.success,
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Finding a mechanic',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'Finding a mechanic near you. They are assigned only after they accept.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 32),
                    if (created != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Booking ID', created.displayNumber),
                            _infoRow(
                              'Service',
                              created.serviceName.isEmpty
                                  ? created.serviceCode
                                  : created.serviceName,
                            ),
                            _infoRow('Amount', formatPaise(created.totalPaise)),
                            _infoRow('Payment', l10n.payAfterTheVisit),
                          ],
                        ),
                      ).animate().slideY(begin: 0.2, delay: 500.ms),
                  ],
                ),
              ),
              AppButton(
                label: 'View booking',
                icon: Icons.receipt_long_rounded,
                onPressed: () => context.pushReplacement(
                  RouteNames.bookingDetails,
                  extra: created?.id ?? bookingId,
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Home',
                isOutlined: true,
                onPressed: () => context.go(RouteNames.home),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
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
