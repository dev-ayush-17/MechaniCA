import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../booking/domain/pricing.dart';

/// Mechanic job offer. Pump this widget in isolation; the server owns expiry.
class OfferScreen extends StatelessWidget {
  const OfferScreen({
    super.key,
    required this.serviceName,
    required this.vehicleType,
    required this.distanceKm,
    required this.totalPaise,
    required this.secondsLeft,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
    this.error,
  });

  final String serviceName;
  final String vehicleType;
  final double distanceKm;
  final int totalPaise;
  final int secondsLeft;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New job')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              serviceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _vehicleLabel(vehicleType),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              '${distanceKm.toStringAsFixed(1)} km away',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              formatPaise(totalPaise),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${secondsLeft}s left',
              key: const Key('offer-countdown'),
              style: const TextStyle(color: AppColors.primaryRed, fontSize: 16),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: AppColors.error)),
            ],
            const Spacer(),
            AppButton(
              label: 'Accept',
              isLoading: busy,
              onPressed: busy ? null : onAccept,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Reject',
              isOutlined: true,
              onPressed: busy ? null : onReject,
            ),
          ],
        ),
      ),
    );
  }

  static String _vehicleLabel(String raw) {
    return switch (raw) {
      'two_wheeler' => 'Two wheeler',
      'four_wheeler' => 'Four wheeler',
      _ => raw.isEmpty ? 'Vehicle' : raw,
    };
  }
}
