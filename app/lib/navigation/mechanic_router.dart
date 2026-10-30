import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/job_chat/presentation/job_chat_screen.dart';
import '../features/mechanic_jobs/presentation/job_actions_screen.dart';
import '../features/mechanic_jobs/presentation/mechanic_jobs_screen.dart';
import '../features/mechanic_jobs/presentation/offer_route_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_home_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_onboarding_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_profile_screen.dart';
import '../features/mechanic_onboarding/presentation/mechanic_shell.dart';
import '../features/mechanic_onboarding/presentation/mechanic_splash_screen.dart';
import '../features/parts_proof/presentation/parts_proof_capture_screen.dart';
import '../features/payments/presentation/earnings_screen.dart';
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
    ShellRoute(
      builder: (_, __, child) => MechanicShell(child: child),
      routes: [
        GoRoute(
          path: MechanicRouteNames.home,
          builder: (_, __) => const MechanicHomeScreen(),
        ),
        GoRoute(
          path: MechanicRouteNames.jobs,
          builder: (_, __) => const MechanicJobsScreen(),
        ),
        GoRoute(
          path: MechanicRouteNames.profile,
          builder: (_, __) => const MechanicProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: MechanicRouteNames.earnings,
      builder: (_, __) => const EarningsScreen(),
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
    GoRoute(
      path: MechanicRouteNames.jobChat,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return JobChatScreen(bookingId: bookingId);
      },
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
