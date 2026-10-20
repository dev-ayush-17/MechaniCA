import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_states.dart';
import '../../widgets/shared/app_widgets.dart';
import 'domain/vehicle_health.dart';

class HealthScoreScreen extends ConsumerStatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  ConsumerState<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends ConsumerState<HealthScoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeBookingsProvider.notifier).load();
    });
  }

  Color _scoreColor(HealthBand band) {
    return switch (band) {
      HealthBand.good => AppColors.success,
      HealthBand.fair => AppColors.warning,
      HealthBand.poor => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(homeBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Health Score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (_, __) => ErrorState(
          message: 'Failed to load health score',
          onRetry: () => ref.read(homeBookingsProvider.notifier).load(),
        ),
        data: (bookings) {
          final health = healthFromLastService(
            lastCompletedServiceAt(bookings),
            now: DateTime.now(),
          );
          final color = _scoreColor(health.band);
          final categories = ['Engine', 'Brakes', 'Battery', 'Tyres', 'Oil'];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                value: health.score.toDouble(),
                                color: color,
                                radius: 20,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: (100 - health.score).toDouble(),
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
                              '${health.score}',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              health.label,
                              style: TextStyle(
                                color: color,
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
                const Center(
                  child: Text(
                    kHealthFromLastService,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Health Indicators',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...categories.asMap().entries.map(
                      (entry) => _IndicatorCard(
                        name: entry.value,
                        score: health.score,
                        label: health.label,
                        color: color,
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: entry.key * 80),
                          ),
                    ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Book Service Now',
                  icon: Icons.build_rounded,
                  onPressed: () => context.push(RouteNames.booking),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.name,
    required this.score,
    required this.label,
    required this.color,
  });

  final String name;
  final int score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StatusBadge(label: label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Same as last service',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
