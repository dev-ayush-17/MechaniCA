import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_screens.dart';
import '../features/admin/presentation/admin_shell.dart';
import 'admin_route_names.dart';

final adminRouter = GoRouter(
  initialLocation: AdminRouteNames.users,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: AdminRouteNames.root, redirect: (_, __) => AdminRouteNames.users),
        GoRoute(path: AdminRouteNames.users, builder: (_, __) => const UsersScreen()),
        GoRoute(path: AdminRouteNames.verification, builder: (_, __) => const VerificationScreen()),
        GoRoute(path: AdminRouteNames.orders, builder: (_, __) => const OrdersScreen()),
        GoRoute(path: AdminRouteNames.revenue, builder: (_, __) => const RevenueScreen()),
        GoRoute(path: AdminRouteNames.coupons, builder: (_, __) => const CouponsScreen()),
        GoRoute(path: AdminRouteNames.disputes, builder: (_, __) => const DisputesScreen()),
        GoRoute(path: AdminRouteNames.audit, builder: (_, __) => const AuditScreen()),
      ],
    ),
  ],
);
