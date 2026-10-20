import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/mechanic_repository.dart';
import 'mechanic_controller.dart';

class MechanicHomeScreen extends ConsumerStatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  ConsumerState<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends ConsumerState<MechanicHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(mechanicProvider.notifier).refresh());
  }

  Future<void> _toggle(bool value) async {
    final ok = await ref.read(mechanicProvider.notifier).setOnline(value);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(mechanicProvider).error;
      if (err != null) showAppSnackbar(context, err);
    }
  }

  String _statusLabel(VerificationStatus status) => switch (status) {
        VerificationStatus.draft => 'Complete your application',
        VerificationStatus.pending => 'Verification pending',
        VerificationStatus.approved => 'Verified',
        VerificationStatus.rejected => 'Rejected — update and resubmit',
      };

  @override
  Widget build(BuildContext context) {
    final mechanic = ref.watch(mechanicProvider);
    final profile = mechanic.profile;
    final canOnline = profile?.canGoOnline ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mechanic'),
        actions: [
          if (profile != null &&
              profile.verificationStatus != VerificationStatus.pending &&
              profile.verificationStatus != VerificationStatus.approved)
            TextButton(
              onPressed: () => context.push(MechanicRouteNames.onboarding),
              child: const Text('Application'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mechanic.isLoading) const LinearProgressIndicator(),
            Text(
              profile == null
                  ? 'Loading profile…'
                  : _statusLabel(profile.verificationStatus),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (profile?.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                profile!.rejectionReason!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Earnings'),
              subtitle: const Text(
                'Recorded earnings. Bank payout is not live yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () => context.push(MechanicRouteNames.earnings),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(
                MechanicRouteNames.partsProof,
                extra: const {'bookingId': 'demo-booking', 'lineId': 'demo-line'},
              ),
              child: const Text('Parts photos'),
            ),
            SwitchListTile(
              title: const Text('Go online'),
              subtitle: Text(
                canOnline
                    ? 'You will receive job offers when online.'
                    : 'Available after admin verification.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              value: profile?.online ?? false,
              onChanged: canOnline ? _toggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
