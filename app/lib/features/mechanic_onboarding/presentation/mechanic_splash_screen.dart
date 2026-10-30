import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/mechanic_repository.dart';
import 'mechanic_controller.dart';

class MechanicSplashScreen extends ConsumerStatefulWidget {
  const MechanicSplashScreen({super.key});

  @override
  ConsumerState<MechanicSplashScreen> createState() =>
      _MechanicSplashScreenState();
}

class _MechanicSplashScreenState extends ConsumerState<MechanicSplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    bool signedIn = false;
    try {
      final restoring = ref.read(authProvider.notifier).restore();
      await Future<void>.delayed(const Duration(seconds: 2));
      signedIn = await restoring.timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      signedIn = false;
    }
    if (!mounted) return;
    if (!signedIn) {
      context.go(MechanicRouteNames.login);
      return;
    }
    final account = ref.read(authProvider).account;
    if (account?.role == 'customer') {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Customer account'),
          content: const Text(
            'This phone is registered as a customer account. '
            'Use the MechUpp customer app, or sign in with a mechanic number.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                context.go(MechanicRouteNames.login);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await ref.read(mechanicProvider.notifier).refresh();
    if (!mounted) return;
    final profile = ref.read(mechanicProvider).profile;
    final needsOnboarding = profile == null ||
        profile.verificationStatus == VerificationStatus.draft ||
        profile.verificationStatus == VerificationStatus.rejected;
    context.go(needsOnboarding ? MechanicRouteNames.onboarding : MechanicRouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'MechUpp Mechanic',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
