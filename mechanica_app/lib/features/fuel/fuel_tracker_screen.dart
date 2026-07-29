import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── FUEL TRACKER SCREEN ──────────────────────────────────────────────────────

class FuelTrackerScreen extends ConsumerStatefulWidget {
  const FuelTrackerScreen({super.key});
  @override
  ConsumerState<FuelTrackerScreen> createState() => _FuelTrackerScreenState();
}

class _FuelTrackerScreenState extends ConsumerState<FuelTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fuelProvider.notifier).load('bike_001');
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuelAsync = ref.watch(fuelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fuel Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteNames.addFuelLog),
          ),
        ],
      ),
      body: fuelAsync.when(
        loading: () => const ShimmerList(),
        error: (_, __) => const ErrorState(message: 'Failed to load fuel data'),
        data: (logs) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        Expanded(child: _FuelStat('₹1,250', 'This Month', Icons.attach_money_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _FuelStat('42 L', 'Total Litres', Icons.local_gas_station_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _FuelStat('45 km/L', 'Avg. Mileage', Icons.speed_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Monthly chart
                    const Text('Monthly Spending',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16)),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 2000,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(
                                  ['Jan', 'Feb', 'Mar', 'Apr', 'May'][v.toInt() % 5],
                                  style: const TextStyle(
                                      color: AppColors.textTertiary, fontSize: 10),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          barGroups: [800, 1200, 950, 1450, 1250]
                              .asMap()
                              .entries
                              .map(
                                (e) => BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.toDouble(),
                                      color: e.key == 4
                                          ? AppColors.primaryRed
                                          : AppColors.primaryRed.withValues(alpha: 0.4),
                                      width: 20,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Fuel Logs',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final log = logs[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.local_gas_station_rounded,
                              color: AppColors.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.litres} Litres • ₹${log.pricePerLitre}/L',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(log.stationName ?? 'Unknown Station',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 11)),
                              Text('Odometer: ${log.odometer} km',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary, fontSize: 10)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${log.totalCost.toInt()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            Text('${log.date.day} May',
                                style: const TextStyle(
                                    color: AppColors.textTertiary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: logs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _FuelStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _FuelStat(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryRed),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
        ],
      ),
    );
  }
}

// ─── ADD FUEL LOG SCREEN ──────────────────────────────────────────────────────

class AddFuelLogScreen extends ConsumerStatefulWidget {
  const AddFuelLogScreen({super.key});
  @override
  ConsumerState<AddFuelLogScreen> createState() => _AddFuelLogScreenState();
}

class _AddFuelLogScreenState extends ConsumerState<AddFuelLogScreen> {
  final _litresCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '103.50');
  final _odomCtrl = TextEditingController();
  final _stationCtrl = TextEditingController(text: 'Indian Oil, Patna');
  bool _isLoading = false;

  @override
  void dispose() {
    _litresCtrl.dispose();
    _priceCtrl.dispose();
    _odomCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Fuel Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Litres Filled'),
            AppTextField(
              hint: 'e.g. 5.5',
              controller: _litresCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const _Label('Price per Litre (₹)'),
            AppTextField(
              hint: 'e.g. 103.50',
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const _Label('Odometer Reading (km)'),
            AppTextField(
              hint: 'e.g. 12500',
              controller: _odomCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const _Label('Fuel Station'),
            AppTextField(hint: 'e.g. Indian Oil, Patna', controller: _stationCtrl),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save Log',
              isLoading: _isLoading,
              onPressed: () async {
                if (_litresCtrl.text.isEmpty || _odomCtrl.text.isEmpty) {
                  showAppSnackbar(context, 'Please fill all fields', isError: true);
                  return;
                }
                setState(() => _isLoading = true);
                final litres = double.tryParse(_litresCtrl.text) ?? 0;
                final price = double.tryParse(_priceCtrl.text) ?? 103.5;
                final log = FuelLogModel(
                  id: 'fl_${DateTime.now().millisecondsSinceEpoch}',
                  bikeId: 'bike_001',
                  litres: litres,
                  pricePerLitre: price,
                  totalCost: litres * price,
                  odometer: int.tryParse(_odomCtrl.text) ?? 0,
                  stationName: _stationCtrl.text,
                  date: DateTime.now(),
                );
                await ref.read(fuelProvider.notifier).addLog(log);
                if (mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, 'Fuel log saved!');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
