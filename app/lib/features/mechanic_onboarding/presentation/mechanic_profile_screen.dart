import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/mechanic_repository.dart';
import 'mechanic_controller.dart';

class MechanicProfileScreen extends ConsumerStatefulWidget {
  const MechanicProfileScreen({super.key});

  @override
  ConsumerState<MechanicProfileScreen> createState() =>
      _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends ConsumerState<MechanicProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(authProvider.notifier).restore();
      await ref.read(mechanicProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider).account;
    final mechanic = ref.watch(mechanicProvider);
    final profile = mechanic.profile;
    final name = (profile != null && profile.displayName.isNotEmpty)
        ? profile.displayName
        : ((account?.name.isNotEmpty ?? false) ? account!.name : 'Mechanic');
    final phone = account?.phoneE164 ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.bikeCardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryRed,
                  child: Text(
                    name.isEmpty ? 'M' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        profile == null
                            ? 'Loading…'
                            : profile.canGoOnline
                                ? (profile.online ? 'Online' : 'Offline · verified')
                                : 'Verification: ${profile.verificationStatus.name}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 16),
            _row('Experience', '${profile.yearsExperience} years'),
            _row(
              'Languages',
              profile.languages.isEmpty ? '—' : profile.languages.join(', '),
            ),
            _row(
              'Service area',
              profile.serviceArea == null
                  ? 'Not set'
                  : '${profile.serviceArea!.lat.toStringAsFixed(4)}, '
                      '${profile.serviceArea!.lng.toStringAsFixed(4)} · '
                      '${profile.serviceArea!.radiusKm.toStringAsFixed(0)} km',
            ),
          ],
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Earnings'),
            subtitle: const Text(
              'Recorded job share. Bank payout is not live yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () => context.push(MechanicRouteNames.earnings),
          ),
          if (profile != null &&
              profile.verificationStatus != VerificationStatus.approved)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Application'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () => context.push(MechanicRouteNames.onboarding),
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Log out',
            isOutlined: true,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(MechanicRouteNames.login);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
