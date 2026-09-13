import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for logo
            Icon(Icons.build_circle, size: 100, color: AppTheme.primaryRed),
            const SizedBox(height: 24),
            Text(
              'MechUpp',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Bike, Our Responsibility.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 100),
            // Placeholder for the bike image at the bottom
            Icon(Icons.motorcycle, size: 150, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
