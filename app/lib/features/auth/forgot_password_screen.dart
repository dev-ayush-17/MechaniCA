import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_widgets.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Enter your registered mobile number to reset', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AppTextField(hint: 'Mobile Number', keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            AppButton(label: 'Send OTP', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }
}

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

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});
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
                child: const Icon(Icons.notifications_outlined, size: 64, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 32),
              const Text('Stay Updated', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Get real-time updates about your bike service, booking status and exclusive offers.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Allow Notifications', onPressed: () => context.go(RouteNames.home)),
              const SizedBox(height: 12),
              AppButton(label: 'Maybe Later', isOutlined: true, onPressed: () => context.go(RouteNames.home)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
