import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';


class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});
  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _progressTimer;

  final _steps = [
    ('Pickup Assigned', '10:10 AM', Icons.assignment_outlined),
    ('Bike Picked', '10:30 AM', Icons.two_wheeler),
    ('Reached Workshop', '11:00 AM', Icons.store),
    ('Repair in Progress', '11:20 AM', Icons.build_rounded),
    ('Quality Check', '1:00 PM', Icons.verified_rounded),
    ('Out for Delivery', '1:30 PM', Icons.local_shipping_rounded),
    ('Delivered', '2:00 PM', Icons.home_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Auto-advance simulation
    _progressTimer = Timer.periodic(const Duration(seconds: 8), (t) {
      ref.read(trackingProvider.notifier).advance();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _showMechanicSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 36, backgroundColor: AppColors.primaryRed, child: Icon(Icons.person, size: 36, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Rakesh Kumar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Text('Expert Mechanic • 4.8 ⭐', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: AppButton(label: 'Call', icon: Icons.call_rounded, onPressed: () {})),
                const SizedBox(width: 12),
                Expanded(child: AppButton(label: 'Chat', icon: Icons.chat_rounded, isOutlined: true, onPressed: () => context.push(RouteNames.chat))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final current = tracking.currentStepIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () => context.push(RouteNames.serviceProgress, extra: widget.bookingId),
            child: const Text('Progress', style: TextStyle(color: AppColors.primaryRed, fontSize: 12)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Status banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.bikeCardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_steps[current < _steps.length ? current : _steps.length - 1].$1,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            const Text('Your Bike is at Workshop', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _showMechanicSheet, child: const Text('Need Help? Call Us', style: TextStyle(color: AppColors.primaryRed, fontSize: 12))),
                    ],
                  ),
                ),

                // Animated Map Area
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Fake map grid
                      CustomPaint(painter: _MapGridPainter(), child: const SizedBox.expand()),
                      // Route line
                      CustomPaint(painter: _RoutePainter(progress: (current + 1) / _steps.length)),
                      // Current location dot
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value * 0.8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 12,
                        left: 12,
                        child: Text('LIVE MAP', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Timeline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Timeline', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      ...List.generate(_steps.length, (i) {
                        final step = _steps[i];
                        final isDone = i <= current;
                        final isCurrent = i == current;
                        return _TimelineItem(
                          icon: step.$3,
                          title: step.$1,
                          time: step.$2,
                          isDone: isDone,
                          isCurrent: isCurrent,
                          isLast: i == _steps.length - 1,
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 80));
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mechanic card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _showMechanicSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 24, backgroundColor: AppColors.primaryRed, child: Icon(Icons.person, color: Colors.white, size: 24)),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rakesh Kumar', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('Mechanic', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                Text('⭐ 4.8 • 120+ services', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _MechanicAction(Icons.call_rounded, () {}),
                              const SizedBox(width: 8),
                              _MechanicAction(Icons.chat_rounded, () => context.push(RouteNames.chat)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.primaryRed : isDone ? AppColors.success : AppColors.textTertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDone || isCurrent ? color.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: isDone || isCurrent ? color : AppColors.divider, width: isCurrent ? 2 : 1),
              ),
              child: Icon(icon, size: 16, color: isDone || isCurrent ? color : AppColors.textTertiary),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 2,
                height: 36,
                color: isDone ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: isDone || isCurrent ? Colors.white : AppColors.textTertiary, fontSize: 13, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400)),
                Text(time, style: TextStyle(color: isDone ? AppColors.success : AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MechanicAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MechanicAction(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryRed),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RoutePainter extends CustomPainter {
  final double progress;
  const _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryRed
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final end = Offset(size.width * progress, size.height / 2);
    canvas.drawLine(Offset(20, size.height / 2), end, paint);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress;
}

// ─── SERVICE PROGRESS SCREEN ──────────────────────────────────────────────────

class ServiceProgressScreen extends ConsumerWidget {
  final String bookingId;
  const ServiceProgressScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Progress'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.bikeCardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repair In Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      StatusBadge(label: 'Active', color: AppColors.primaryRed),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Engine oil change', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('60%', style: TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Work items
            const Text('Work Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[
              ('Full body check-up', true),
              ('Engine oil change', true),
              ('Air filter cleaned', true),
              ('Chain lubrication done', false),
              ('Brake adjustment', false),
            ].map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(item.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: item.$2 ? AppColors.success : AppColors.textTertiary, size: 18),
                  const SizedBox(width: 10),
                  Text(item.$1, style: TextStyle(color: item.$2 ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )).toList(),

            const SizedBox(height: 20),
            // Parts changed
            const Text('Parts Changed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[
              ('Engine Oil (1L)', '1', '₹250'),
              ('Air Filter', '1', '₹150'),
              ('Spark Plug', '1', '₹80'),
            ].map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.settings_rounded, color: AppColors.primaryRed, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.$1, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('x${p.$2}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text(p.$3, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),

            const SizedBox(height: 20),
            // Mechanic notes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.notes_rounded, color: AppColors.primaryRed, size: 16),
                    SizedBox(width: 8),
                    Text('Mechanic Notes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Bike in overall good condition. Engine running smoothly after oil change. Recommend checking rear tyre pressure next month.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
