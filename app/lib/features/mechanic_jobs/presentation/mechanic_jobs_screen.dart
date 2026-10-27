import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../../widgets/shared/app_states.dart';
import '../../booking/domain/booking.dart';
import '../../booking/domain/pricing.dart';
import '../../mechanic_onboarding/presentation/mechanic_session_ticker.dart';
import '../domain/job_offer.dart';

class MechanicJobsScreen extends ConsumerStatefulWidget {
  const MechanicJobsScreen({super.key});

  @override
  ConsumerState<MechanicJobsScreen> createState() => _MechanicJobsScreenState();
}

class _MechanicJobsScreenState extends ConsumerState<MechanicJobsScreen> {
  JobOffer? _openOffer;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_refresh);
  }

  Future<void> _refresh() async {
    ref.read(homeBookingsProvider.notifier).load();
    final result = await ref.read(offerApiProvider).getOpen();
    if (!mounted) return;
    setState(() {
      _openOffer = switch (result) {
        Ok(:final value) => value,
        Err() => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mechanicSessionTickerProvider, (previous, next) {
      if (next.pendingOfferId != previous?.pendingOfferId) {
        _refresh();
      }
    });
    final bookingsAsync = ref.watch(homeBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Jobs')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: bookingsAsync.when(
          loading: () => const ShimmerList(),
          error: (err, _) => ErrorState(
            message: err.toString(),
            onRetry: _refresh,
          ),
          data: (bookings) {
            final active = bookings
                .where(
                  (b) =>
                      b.status == BookingStatus.mechanicAssigned ||
                      b.status == BookingStatus.enRoute ||
                      b.status == BookingStatus.arrived ||
                      b.status == BookingStatus.inService,
                )
                .toList();
            final done = bookings
                .where(
                  (b) =>
                      b.status == BookingStatus.completed ||
                      b.status == BookingStatus.paid,
                )
                .toList();
            if (_openOffer == null && active.isEmpty && done.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Text(
                    'No jobs yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Go online on Home. Incoming offers and accepted jobs show here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_openOffer != null) ...[
                  const Text(
                    'Incoming offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OfferTile(
                    offer: _openOffer!,
                    onTap: () => context.push(
                      MechanicRouteNames.offerPath(_openOffer!.id),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (active.isNotEmpty) ...[
                  const Text(
                    'In progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final job in active)
                    _JobTile(
                      booking: job,
                      onTap: () => context.push(
                        MechanicRouteNames.jobPath(
                          job.id,
                          status: job.status.name,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
                if (done.isNotEmpty) ...[
                  const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final job in done)
                    _JobTile(
                      booking: job,
                      onTap: () => context.push(
                        MechanicRouteNames.jobPath(
                          job.id,
                          status: job.status.name,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onTap});

  final JobOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.serviceName.isEmpty ? 'New job' : offer.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${offer.distanceKm.toStringAsFixed(1)} km · ${formatPaise(offer.totalPaise)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = booking.serviceName.isEmpty
        ? booking.serviceCode
        : booking.serviceName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${booking.displayNumber} · ${booking.status.label}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatPaise(booking.totalPaise),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
