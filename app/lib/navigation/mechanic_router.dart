import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/mechanic_jobs/presentation/job_actions_screen.dart';
import '../features/mechanic_jobs/presentation/offer_route_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_home_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_onboarding_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_splash_screen.dart';
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
      path: MechanicRouteNames.offer,
      builder: (_, state) => OfferRouteScreen(
        offerId: state.pathParameters['offerId'] ?? '',
      ),
    ),
    GoRoute(
      path: MechanicRouteNames.job,
      builder: (_, state) => JobActionsScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
        initialStatus:
            state.uri.queryParameters['status'] ?? 'mechanicAssigned',
      ),
    ),
  ],
);
