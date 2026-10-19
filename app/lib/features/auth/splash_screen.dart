import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _bikeCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _bikeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _bikeCtrl.forward();
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) context.go(RouteNames.onboarding);
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _bikeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  AppColors.primaryRed.withValues(alpha: 0.15),
                  AppColors.background,
                ],
              ),
            ),
          ),
          // Red glow at top
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              const Spacer(),
              // Logo section
              AnimatedBuilder(
                animation: _logoCtrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoCtrl.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _logoCtrl.value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppShadows.red,
                      ),
                      child: const Icon(Icons.build_circle_rounded, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MechUpp',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Bike. Our Responsibility.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bike illustration
              AnimatedBuilder(
                animation: _bikeCtrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bikeCtrl.value,
                    child: Transform.translate(
                      offset: Offset(60 * (1 - _bikeCtrl.value), 0),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.motorcycle,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
                  borderRadius: BorderRadius.circular(4),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }
}
