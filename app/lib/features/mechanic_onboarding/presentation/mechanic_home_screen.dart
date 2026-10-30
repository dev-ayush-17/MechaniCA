import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/mechanic_repository.dart';
import 'mechanic_controller.dart';
import 'mechanic_session_ticker.dart';

class MechanicHomeScreen extends ConsumerStatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  ConsumerState<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends ConsumerState<MechanicHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(authProvider.notifier).restore();
      await ref.read(mechanicProvider.notifier).refresh();
      await ref.read(homeBookingsProvider.notifier).load();
    });
  }

  Future<void> _toggle(bool value) async {
    final ok = await ref.read(mechanicProvider.notifier).setOnline(value);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(mechanicProvider).error;
      if (err != null) showAppSnackbar(context, err);
      return;
    }
    if (value) {
      await ref.read(mechanicProvider.notifier).heartbeat();
      await ref.read(mechanicSessionTickerProvider.notifier).tick();
      await ref.read(homeBookingsProvider.notifier).load();
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
    final ticker = ref.watch(mechanicSessionTickerProvider);
    final bookings = ref.watch(homeBookingsProvider).whenOrNull(data: (list) => list) ?? [];
    final profile = mechanic.profile;
    final canOnline = profile?.canGoOnline ?? false;
    final error = mechanic.error ?? ticker.pollError;
    final active = bookings
        .where(
          (b) =>
              b.status == BookingStatus.mechanicAssigned ||
              b.status == BookingStatus.enRoute ||
              b.status == BookingStatus.arrived ||
              b.status == BookingStatus.inService,
        )
        .toList();
    final name = profile == null || profile.displayName.isEmpty
        ? 'Mechanic'
        : profile.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (mechanic.isLoading) const LinearProgressIndicator(),
          Text(
            'Hi, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile == null
                ? (error == null ? 'Loading profile…' : 'Could not load profile')
                : _statusLabel(profile.verificationStatus),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: AppColors.error)),
          ],
          if (profile?.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              profile!.rejectionReason!,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Go online'),
            subtitle: Text(
              canOnline
                  ? 'Job offers appear while you are online.'
                  : 'Available after admin verification.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            value: profile?.online ?? false,
            onChanged: canOnline ? _toggle : null,
          ),
          if (ticker.pendingOfferId != null) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Open incoming job',
              onPressed: () => context.push(
                MechanicRouteNames.offerPath(ticker.pendingOfferId!),
              ),
            ),
          ],
          if (active.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Current job',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final job in active)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  job.serviceName.isEmpty ? job.serviceCode : job.serviceName,
                ),
                subtitle: Text(
                  job.status.label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
                onTap: () => context.push(
                  MechanicRouteNames.jobPath(job.id, status: job.status.name),
                ),
              ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('All jobs'),
            subtitle: const Text(
              'Incoming offers, in-progress, and completed work.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () => context.go(MechanicRouteNames.jobs),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Earnings'),
            subtitle: const Text(
              'Recorded earnings. Bank payout is not live yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () => context.push(MechanicRouteNames.earnings),
          ),
        ],
      ),
    );
  }
}
