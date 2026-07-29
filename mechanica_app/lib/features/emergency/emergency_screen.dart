import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../widgets/shared/app_widgets.dart';

// ─── EMERGENCY SCREEN ─────────────────────────────────────────────────────────

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      ('Flat Tyre', Icons.circle_outlined, 'Emergency tyre fix'),
      ('Battery Dead', Icons.battery_0_bar_rounded, 'Jump start or replacement'),
      ('Breakdown', Icons.warning_amber_rounded, 'On-road recovery'),
      ('Fuel Empty', Icons.local_gas_station_rounded, 'Emergency fuel delivery'),
      ('Accident', Icons.car_crash_rounded, 'Accident response'),
      ('Other', Icons.more_horiz_rounded, 'Any other emergency'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SOS Button
            GestureDetector(
              onLongPress: () => context.push(RouteNames.emergencyTracking, extra: 'SOS'),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(colors: [AppColors.primaryRed, Color(0xFF7B0000)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.6), blurRadius: 40, spreadRadius: 10)],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SOS', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4)),
                    Text('Hold for 2s', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            const Text('Need Immediate Help?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('We are here for you', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Emergency Type', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: types.length,
              itemBuilder: (_, i) {
                final type = types[i];
                return GestureDetector(
                  onTap: () => context.push(RouteNames.emergencyTracking, extra: type.$1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type.$2, size: 32, color: AppColors.primaryRed),
                        const SizedBox(height: 8),
                        Text(type.$1, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        Text(type.$3, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Call Support',
              icon: Icons.call_rounded,
              onPressed: () => showAppSnackbar(context, 'Calling emergency support...'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EMERGENCY TRACKING SCREEN ────────────────────────────────────────────────

class EmergencyTrackingScreen extends StatefulWidget {
  final String emergencyType;
  const EmergencyTrackingScreen({super.key, required this.emergencyType});
  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  int _etaMinutes = 12;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.emergencyType} Assistance'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Live status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryRed, width: 2),
                      ),
                      child: const Icon(Icons.sos_rounded, size: 40, color: AppColors.primaryRed),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Help is on the Way!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('ETA: $_etaMinutes minutes', style: const TextStyle(color: AppColors.primaryRed, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Steps
            ...[
              ('Request Received', true, Icons.check_circle),
              ('Nearest Mechanic Assigned', true, Icons.person_pin_circle),
              ('Mechanic En Route', false, Icons.route_rounded),
              ('Arrived', false, Icons.location_on_rounded),
            ].map((step) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: step.$2 ? Border.all(color: AppColors.success.withValues(alpha: 0.3)) : null,
              ),
              child: Row(
                children: [
                  Icon(step.$3, color: step.$2 ? AppColors.success : AppColors.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Text(step.$1, style: TextStyle(color: step.$2 ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: step.$2 ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            )).toList(),

            const SizedBox(height: 20),
            AppButton(
              label: 'Call Mechanic',
              icon: Icons.call_rounded,
              onPressed: () => showAppSnackbar(context, 'Calling assigned mechanic...'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel Request',
              isOutlined: true,
              color: AppColors.error,
              onPressed: () {
                context.pop();
                showAppSnackbar(context, 'Emergency request cancelled');
              },
            ),
          ],
        ),
      ),
    );
  }
}
