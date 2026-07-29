import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/home/main_shell.dart';
import '../features/home/home_screen.dart';
import '../features/home/notifications_screen.dart';
import '../features/bikes/my_bikes_screen.dart';
import '../features/bikes/add_bike_screen.dart';
import '../features/bikes/bike_details_screen.dart';
import '../features/booking/booking_flow_screen.dart';
import '../features/booking/booking_success_screen.dart';
import '../features/booking/booking_details_screen.dart';
import '../features/booking/reschedule_screen.dart';
import '../features/tracking/live_tracking_screen.dart';
import '../features/tracking/service_progress_screen.dart';
import '../features/inspection/digital_inspection_screen.dart';
import '../features/inspection/photo_gallery_screen.dart';
import '../features/invoice/invoice_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/wallet/add_money_screen.dart';
import '../features/offers/offers_screen.dart';
import '../features/offers/offer_details_screen.dart';
import '../features/membership/membership_screen.dart';
import '../features/membership/purchase_success_screen.dart';
import '../features/referral/refer_earn_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/emergency/emergency_tracking_screen.dart';
import '../features/documents/documents_screen.dart';
import '../features/documents/document_viewer_screen.dart';
import '../features/support/support_screen.dart';
import '../features/support/chat_screen.dart';
import '../features/support/ticket_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/addresses_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/fuel/fuel_tracker_screen.dart';
import '../features/fuel/add_fuel_log_screen.dart';
import '../features/health/health_score_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/service_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.otp,
      builder: (_, state) {
        final phone = state.extra as String? ?? '';
        return OTPScreen(phone: phone);
      },
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RouteNames.locationPermission,
      builder: (_, __) => const LocationPermissionScreen(),
    ),
    GoRoute(
      path: RouteNames.notificationPermission,
      builder: (_, __) => const NotificationPermissionScreen(),
    ),

    // ── Main Shell ────────────────────────────────────────────────────────────
    ShellRoute(
      builder: (_, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
        GoRoute(path: RouteNames.myBikes, builder: (_, __) => const MyBikesScreen()),
        GoRoute(path: RouteNames.history, builder: (_, __) => const HistoryScreen()),
        GoRoute(path: RouteNames.wallet, builder: (_, __) => const WalletScreen()),
        GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Notifications ─────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.notifications,
      builder: (_, __) => const NotificationsScreen(),
    ),

    // ── Bikes ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.addBike,
      builder: (_, __) => const AddBikeScreen(),
    ),
    GoRoute(
      path: RouteNames.bikeDetails,
      builder: (_, state) {
        final bikeId = state.extra as String? ?? '';
        return BikeDetailsScreen(bikeId: bikeId);
      },
    ),

    // ── Booking ───────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.booking,
      builder: (_, __) => const BookingFlowScreen(),
    ),
    GoRoute(
      path: RouteNames.bookingSuccess,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return BookingSuccessScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: RouteNames.bookingDetails,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return BookingDetailsScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: RouteNames.reschedule,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return RescheduleScreen(bookingId: bookingId);
      },
    ),

    // ── Tracking ──────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.liveTracking,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return LiveTrackingScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: RouteNames.serviceProgress,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return ServiceProgressScreen(bookingId: bookingId);
      },
    ),

    // ── Inspection ────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.inspection,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return DigitalInspectionScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: RouteNames.photoGallery,
      builder: (_, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return PhotoGalleryScreen(
          photos: List<String>.from(args['photos'] ?? []),
          initialIndex: args['index'] ?? 0,
        );
      },
    ),

    // ── Invoice ───────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.invoice,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return InvoiceScreen(bookingId: bookingId);
      },
    ),

    // ── Wallet ────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.addMoney,
      builder: (_, __) => const AddMoneyScreen(),
    ),

    // ── Offers ────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.offers,
      builder: (_, __) => const OffersScreen(),
    ),
    GoRoute(
      path: RouteNames.offerDetails,
      builder: (_, state) {
        final offerId = state.extra as String? ?? '';
        return OfferDetailsScreen(offerId: offerId);
      },
    ),

    // ── Membership ────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.membership,
      builder: (_, __) => const MembershipScreen(),
    ),
    GoRoute(
      path: RouteNames.purchaseSuccess,
      builder: (_, state) {
        final plan = state.extra as String? ?? 'Gold';
        return PurchaseSuccessScreen(planName: plan);
      },
    ),

    // ── Referral ──────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.referEarn,
      builder: (_, __) => const ReferEarnScreen(),
    ),

    // ── Emergency ─────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.emergency,
      builder: (_, __) => const EmergencyScreen(),
    ),
    GoRoute(
      path: RouteNames.emergencyTracking,
      builder: (_, state) {
        final type = state.extra as String? ?? 'Breakdown';
        return EmergencyTrackingScreen(emergencyType: type);
      },
    ),

    // ── Documents ─────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.documents,
      builder: (_, __) => const DocumentsScreen(),
    ),
    GoRoute(
      path: RouteNames.documentViewer,
      builder: (_, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return DocumentViewerScreen(
          title: args['title'] ?? '',
          docType: args['docType'] ?? '',
        );
      },
    ),

    // ── Support ───────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.support,
      builder: (_, __) => const SupportScreen(),
    ),
    GoRoute(
      path: RouteNames.chat,
      builder: (_, __) => const ChatScreen(),
    ),
    GoRoute(
      path: RouteNames.ticket,
      builder: (_, __) => const TicketScreen(),
    ),

    // ── Profile sub-pages ─────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.editProfile,
      builder: (_, __) => const EditProfileScreen(),
    ),
    GoRoute(
      path: RouteNames.addresses,
      builder: (_, __) => const AddressesScreen(),
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (_, __) => const SettingsScreen(),
    ),

    // ── Fuel ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.fuelTracker,
      builder: (_, __) => const FuelTrackerScreen(),
    ),
    GoRoute(
      path: RouteNames.addFuelLog,
      builder: (_, __) => const AddFuelLogScreen(),
    ),

    // ── Health ────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.healthScore,
      builder: (_, __) => const HealthScoreScreen(),
    ),

    // ── History ───────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.serviceDetail,
      builder: (_, state) {
        final bookingId = state.extra as String? ?? '';
        return ServiceDetailScreen(bookingId: bookingId);
      },
    ),
  ],
);
