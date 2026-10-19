import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthScoreProvider('bike_001'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Health Score'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop()),
      ),
      body: healthAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (_, __) =>
            const ErrorState(message: 'Failed to load health score'),
        data: (health) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Circle
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 0,
                          centerSpaceRadius: 72,
                          sections: [
                            PieChartSectionData(
                              value: health.overallScore.toDouble(),
                              color: _scoreColor(health.overallScore),
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value:
                                  (100 - health.overallScore).toDouble(),
                              color: AppColors.divider,
                              radius: 16,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${health.overallScore}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: _scoreColor(health.overallScore),
                            ),
                          ),
                          const Text('/100',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          Text(
                            health.condition,
                            style: TextStyle(
                              color: _scoreColor(health.overallScore),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Last Checked: ${health.lastChecked.day}/${health.lastChecked.month}/${health.lastChecked.year}',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Health Indicators',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Indicators
              ...[
                health.engine,
                health.brakes,
                health.battery,
                health.tyres,
                health.oil,
              ].asMap().entries.map((e) => _IndicatorCard(e.value)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: e.key * 80))),

              const SizedBox(height: 20),
              const Text('Recommendations',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...health.recommendations.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),
              AppButton(
                label: 'Book Service Now',
                icon: Icons.build_rounded,
                onPressed: () => context.push(RouteNames.booking),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _IndicatorCard extends StatelessWidget {
  final dynamic indicator;
  const _IndicatorCard(this.indicator);

  Color _color(String status) {
    switch (status) {
      case 'Good':
        return AppColors.success;
      case 'Moderate':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(indicator.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(indicator.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              StatusBadge(label: indicator.status, color: color),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: indicator.score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(indicator.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text('${indicator.score}/100',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
