import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../models/bike_model.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_states.dart';
import '../../widgets/shared/app_widgets.dart';

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
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.read(bikeProvider.notifier).loadBikes('usr_001')),
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
                      itemBuilder: (_, i) => _BikeCard(
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
        content: Text('Remove ${bike.name} from your garage?', style: const TextStyle(color: AppColors.textSecondary)),
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

class _BikeCard extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BikeCard({required this.bike, required this.onTap, required this.onDelete});

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
                          Text(bike.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          if (bike.isPrimary) ...[
                            const SizedBox(width: 8),
                            const StatusBadge(label: 'Primary', color: AppColors.primaryRed),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(bike.registrationNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${bike.year}  •  ${bike.color}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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

// ─── ADD BIKE SCREEN ──────────────────────────────────────────────────────────

class AddBikeScreen extends ConsumerStatefulWidget {
  const AddBikeScreen({super.key});
  @override
  ConsumerState<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends ConsumerState<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  String _fuelType = 'petrol';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final bike = BikeModel(
      id: 'bike_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_001',
      name: _nameCtrl.text,
      brand: _brandCtrl.text,
      model: _nameCtrl.text,
      registrationNumber: _regCtrl.text,
      year: 2023,
      fuelType: _fuelType,
      odometer: 0,
      color: 'Black',
      isPrimary: false,
      addedAt: DateTime.now(),
    );
    await ref.read(bikeProvider.notifier).addBike(bike);
    if (mounted) {
      setState(() => _isLoading = false);
      showAppSnackbar(context, 'Bike added successfully!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Bike')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Bike Name'),
              AppTextField(hint: 'e.g. Apache RTR 160 4V', controller: _nameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _label('Brand'),
              AppTextField(hint: 'e.g. TVS, Bajaj, Hero', controller: _brandCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _label('Registration Number'),
              AppTextField(hint: 'e.g. BR80Y 0246', controller: _regCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _label('Fuel Type'),
              Row(
                children: ['petrol', 'electric', 'cng'].map((f) {
                  final selected = _fuelType == f;
                  return GestureDetector(
                    onTap: () => setState(() => _fuelType = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryRed : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.primaryRed : AppColors.inputBorder),
                      ),
                      child: Text(f.toUpperCase(), style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              AppButton(label: 'Add Bike', isLoading: _isLoading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

// ─── BIKE DETAILS SCREEN ──────────────────────────────────────────────────────

class BikeDetailsScreen extends ConsumerWidget {
  final String bikeId;
  const BikeDetailsScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikeProvider);
    final bike = bikes.whenOrNull(data: (list) => list.firstWhere((b) => b.id == bikeId, orElse: () => mockBikes.first)) ?? mockBikes.first;

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
                decoration: BoxDecoration(gradient: AppColors.bikeCardGradient),
                child: Center(
                  child: Icon(Icons.motorcycle, size: 120, color: Colors.white.withValues(alpha: 0.15)),
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
                          Text(bike.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(bike.registrationNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                      if (bike.isPrimary)
                        const StatusBadge(label: 'Primary Bike', color: AppColors.primaryRed),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      _StatCard('Odometer', '${bike.odometer} km', Icons.speed_rounded),
                      const SizedBox(width: 10),
                      _StatCard('Year', '${bike.year}', Icons.calendar_today_rounded),
                      const SizedBox(width: 10),
                      _StatCard('Fuel', bike.fuelType, Icons.local_gas_station_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Documents section
                  const Text('Documents', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  _DocRow('Insurance', bike.insuranceExpiry ?? 'N/A', Icons.shield_outlined, AppColors.success, context),
                  _DocRow('PUC Certificate', bike.pucExpiry ?? 'N/A', Icons.task_alt_rounded, AppColors.warning, context),
                  _DocRow('RC Book', 'Valid', Icons.description_outlined, AppColors.info, context),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(child: AppButton(label: 'Book Service', onPressed: () => context.push(RouteNames.booking))),
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

  Widget _StatCard(String label, String value, IconData icon) {
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _DocRow(String name, String value, IconData icon, Color color, BuildContext context) {
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
