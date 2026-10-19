import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../mock/mock_data.dart';
import '../../../navigation/route_names.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/shared/app_states.dart';
import '../../../widgets/shared/app_widgets.dart';

class BikeDetailsScreen extends ConsumerWidget {
  final String bikeId;
  const BikeDetailsScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikeProvider);
    final bike = bikes.whenOrNull(
          data: (list) => list.firstWhere(
            (b) => b.id == bikeId,
            orElse: () => mockBikes.first,
          ),
        ) ??
        mockBikes.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.bikeCardGradient),
                child: Center(
                  child: Icon(
                    Icons.motorcycle,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bike.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            bike.registrationNumber,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                      if (bike.isPrimary)
                        const StatusBadge(label: 'Primary Bike', color: AppColors.primaryRed),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statCard('Odometer', '${bike.odometer} km', Icons.speed_rounded),
                      const SizedBox(width: 10),
                      _statCard('Year', '${bike.year}', Icons.calendar_today_rounded),
                      const SizedBox(width: 10),
                      _statCard('Fuel', bike.fuelType, Icons.local_gas_station_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Documents',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _docRow(
                    'Insurance',
                    bike.insuranceExpiry ?? 'N/A',
                    Icons.shield_outlined,
                    AppColors.success,
                    context,
                  ),
                  _docRow(
                    'PUC Certificate',
                    bike.pucExpiry ?? 'N/A',
                    Icons.task_alt_rounded,
                    AppColors.warning,
                    context,
                  ),
                  _docRow('RC Book', 'Valid', Icons.description_outlined, AppColors.info, context),
                  const SizedBox(height: 20),
                  const Text(
                    'Service history',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    icon: Icons.history,
                    title: 'No services yet',
                    subtitle: 'Completed bookings for this bike will show up here.',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Book Service',
                          onPressed: () => context.push(RouteNames.booking),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Service History',
                          isOutlined: true,
                          onPressed: () => context.go(RouteNames.history),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryRed),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _docRow(String name, String value, IconData icon, Color color, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.documents),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14))),
            Text(value, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
