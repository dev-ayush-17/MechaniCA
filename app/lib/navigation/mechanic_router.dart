import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_home_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_onboarding_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_splash_screen.dart';
import '../features/parts_proof/presentation/parts_proof_capture_screen.dart';
import 'mechanic_route_names.dart';

final mechanicRouter = GoRouter(
  initialLocation: MechanicRouteNames.splash,
  routes: [
    GoRoute(
      path: MechanicRouteNames.splash,
      builder: (_, __) => const MechanicSplashScreen(),
    ),
    GoRoute(
      path: MechanicRouteNames.onboarding,
      builder: (_, __) => const MechanicOnboardingScreen(),
    ),
    GoRoute(
      path: MechanicRouteNames.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: MechanicRouteNames.otp,
      builder: (_, state) {
        final phone = state.extra as String? ?? '';
        return OTPScreen(phone: phone);
      },
    ),
    GoRoute(
      path: MechanicRouteNames.home,
      builder: (_, __) => const MechanicHomeScreen(),
    ),
    GoRoute(
      path: MechanicRouteNames.partsProof,
      builder: (_, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return PartsProofCaptureScreen(
          bookingId: extra['bookingId'] ?? 'demo-booking',
          lineId: extra['lineId'] ?? 'demo-line',
        );
      },
    ),
  ],
);
