import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_widgets.dart';

/// Next legal mechanic action. The server still checks the transition.
class JobStatusButtons extends StatelessWidget {
  const JobStatusButtons({
    super.key,
    required this.status,
    required this.onAction,
    this.hasPartLines = false,
    this.hasPendingExtra = false,
    this.busy = false,
  });

  final String status;
  final VoidCallback onAction;
  final bool hasPartLines;
  final bool hasPendingExtra;
  final bool busy;

  String? get label {
    return switch (status) {
      'mechanicAssigned' => 'Start trip',
      'enRoute' => 'Arrived',
      'arrived' => 'Start service',
      'inService' => 'Complete',
      _ => null,
    };
  }

  String get nextStatus {
    return switch (status) {
      'mechanicAssigned' => 'enRoute',
      'enRoute' => 'arrived',
      'arrived' => 'inService',
      'inService' => 'completed',
      _ => status,
    };
  }

  bool get completeBlocked =>
      status == 'inService' && (hasPartLines || hasPendingExtra);

  @override
  Widget build(BuildContext context) {
    final action = label;
    if (action == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (completeBlocked)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              hasPendingExtraCopy,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        AppButton(
          label: action,
          isLoading: busy,
          onPressed: busy || completeBlocked ? null : onAction,
        ),
      ],
    );
  }
}

const hasPendingExtraCopy =
    'Pending extra work must be decided. Jobs with part lines wait for photos.';
