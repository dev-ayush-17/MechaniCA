import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/bike_model.dart';
import '../../../navigation/route_names.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/shared/app_states.dart';
import '../../../widgets/shared/app_widgets.dart';

class MyBikesScreen extends ConsumerStatefulWidget {
  const MyBikesScreen({super.key});
  @override
  ConsumerState<MyBikesScreen> createState() => _MyBikesScreenState();
}

class _MyBikesScreenState extends ConsumerState<MyBikesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bikeProvider.notifier).loadBikes('usr_001');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Bikes')),
      body: bikesAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.read(bikeProvider.notifier).loadBikes('usr_001'),
        ),
        data: (bikes) => Column(
          children: [
            Expanded(
              child: bikes.isEmpty
                  ? EmptyState(
                      icon: Icons.motorcycle_outlined,
                      title: 'No Bikes Added',
                      subtitle: 'Add your first bike to get started',
                      actionLabel: 'Add Bike',
                      onAction: () => context.push(RouteNames.addBike),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bikes.length,
                      itemBuilder: (_, i) => BikeCard(
                        bike: bikes[i],
                        onTap: () => context.push(RouteNames.bikeDetails, extra: bikes[i].id),
                        onDelete: () => _confirmDelete(context, bikes[i]),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 80)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Add New Bike',
                icon: Icons.add,
                onPressed: () => context.push(RouteNames.addBike),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BikeModel bike) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Bike', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${bike.name} from your garage?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bikeProvider.notifier).deleteBike(bike.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class BikeCard extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BikeCard({
    super.key,
    required this.bike,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.bikeCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: bike.isPrimary ? AppColors.primaryRed.withValues(alpha: 0.5) : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.motorcycle, size: 28, color: AppColors.primaryRed),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bike.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (bike.isPrimary) ...[
                            const SizedBox(width: 8),
                            const StatusBadge(label: 'Primary', color: AppColors.primaryRed),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bike.registrationNumber,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${bike.year}  •  ${bike.color}',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  onSelected: (val) {
                    if (val == 'delete') onDelete();
                    if (val == 'edit') context.push(RouteNames.bikeDetails, extra: bike.id);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(Icons.speed_rounded, '${bike.odometer} km'),
                const SizedBox(width: 8),
                _InfoChip(Icons.local_gas_station_rounded, bike.fuelType),
                const SizedBox(width: 8),
                if (bike.insuranceExpiry != null)
                  _InfoChip(Icons.shield_outlined, 'Ins: ${bike.insuranceExpiry}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
