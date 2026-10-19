import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/pricing.dart';

class ExtraWorkCard extends StatelessWidget {
  const ExtraWorkCard({
    super.key,
    required this.name,
    required this.amountPaise,
    required this.onApprove,
    required this.onReject,
  });

  final String name;
  final int amountPaise;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extra work',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(
            formatPaise(amountPaise),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'Approve', onPressed: onApprove, height: 44),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  isOutlined: true,
                  color: AppColors.error,
                  onPressed: onReject,
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
