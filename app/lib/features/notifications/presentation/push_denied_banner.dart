import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

const kPushDeniedBannerCopy =
    'Turn on notifications to know when your mechanic is assigned.';

final pushPermissionDeniedProvider = StateProvider<bool>((ref) => false);

/// Shown at the top of home when push permission was denied (chapter 17).
class HomePushDeniedBanner extends ConsumerWidget {
  const HomePushDeniedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(pushPermissionDeniedProvider)) {
      return const SizedBox.shrink();
    }
    return const PushDeniedBanner();
  }
}

class PushDeniedBanner extends StatelessWidget {
  const PushDeniedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: const Text(
          kPushDeniedBannerCopy,
          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
