import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/notifications/domain/push_permission.dart';
import '../../../features/notifications/presentation/push_denied_banner.dart';
import '../../../navigation/route_names.dart';
import '../../../widgets/shared/app_widgets.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined,
                    size: 64, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 32),
              const Text('Enable Location',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Allow MechUpp to access your location to find nearby workshops and mechanics.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                  label: 'Allow Location',
                  onPressed: () =>
                      context.go(RouteNames.notificationPermission)),
              const SizedBox(height: 12),
              AppButton(
                label: 'Maybe Later',
                isOutlined: true,
                onPressed: () => context.go(RouteNames.notificationPermission),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _allow(BuildContext context, WidgetRef ref) async {
    final status = await ref.read(pushPermissionProvider).requestOnce();
    ref.read(pushPermissionDeniedProvider.notifier).state =
        status == PushPermissionStatus.denied;
    if (context.mounted) context.go(RouteNames.home);
  }

  void _skip(BuildContext context, WidgetRef ref) {
    ref.read(pushPermissionDeniedProvider.notifier).state = true;
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    size: 64, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 32),
              const Text('Stay Updated',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Get real-time updates about your bike service, booking status and exclusive offers.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                  label: 'Allow Notifications',
                  onPressed: () => _allow(context, ref)),
              const SizedBox(height: 12),
              AppButton(
                label: 'Maybe Later',
                isOutlined: true,
                onPressed: () => _skip(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
