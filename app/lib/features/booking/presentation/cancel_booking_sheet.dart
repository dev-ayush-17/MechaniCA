import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../widgets/shared/app_widgets.dart';

const kCancelBlockedCopy =
    "This visit can't be cancelled. Contact support if something is wrong.";

Future<void> showCancelBookingSheet({
  required BuildContext context,
  required BookingStatus status,
  required Future<void> Function(String reason) onCancel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CancelBookingSheet(status: status, onCancel: onCancel),
  );
}

class CancelBookingSheet extends StatefulWidget {
  const CancelBookingSheet({
    super.key,
    required this.status,
    required this.onCancel,
  });

  final BookingStatus status;
  final Future<void> Function(String reason) onCancel;

  @override
  State<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<CancelBookingSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    if (!widget.status.canCancel) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancel Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              kCancelBlockedCopy,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Contact support',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancel Booking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Are you sure you want to cancel?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...['Changed my plans', 'Found better price', 'Emergency', 'Other'].map(
            (reason) => GestureDetector(
              onTap: () => setState(() => _reason = reason),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _reason == reason
                      ? AppColors.primaryRed.withValues(alpha: 0.1)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reason == reason ? AppColors.primaryRed : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _reason == reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _reason == reason
                          ? AppColors.primaryRed
                          : AppColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(reason, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Confirm Cancel',
            color: AppColors.error,
            onPressed: _reason == null
                ? null
                : () async {
                    await widget.onCancel(_reason!);
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}
