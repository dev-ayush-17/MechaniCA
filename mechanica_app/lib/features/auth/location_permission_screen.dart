import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_widgets.dart';

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
                child: const Icon(Icons.location_on_outlined, size: 64, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 32),
              const Text('Enable Location', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Allow MechUpp to access your location to find nearby workshops and mechanics.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Allow Location', onPressed: () => context.go(RouteNames.notificationPermission)),
              const SizedBox(height: 12),
              AppButton(label: 'Maybe Later', isOutlined: true, onPressed: () => context.go(RouteNames.notificationPermission)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
