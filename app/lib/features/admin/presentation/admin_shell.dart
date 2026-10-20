import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../navigation/admin_route_names.dart';
import 'admin_providers.dart';

const adminMinWidth = 1024.0;
const largeScreenMessage = 'Use a larger screen';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < adminMinWidth) {
          return const Scaffold(
            body: Center(
              child: Text(largeScreenMessage, style: TextStyle(color: AppColors.textPrimary)),
            ),
          );
        }
        final role = ref.watch(adminRoleProvider);
        final path = GoRouterState.of(context).uri.path;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index(path),
                onDestinationSelected: (index) => context.go(_paths[index]),
                labelType: NavigationRailLabelType.all,
                backgroundColor: AppColors.surface,
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('Users')),
                  NavigationRailDestination(icon: Icon(Icons.verified_outlined), label: Text('Verify')),
                  NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), label: Text('Orders')),
                  NavigationRailDestination(icon: Icon(Icons.payments_outlined), label: Text('Revenue')),
                  NavigationRailDestination(icon: Icon(Icons.local_offer_outlined), label: Text('Coupons')),
                  NavigationRailDestination(icon: Icon(Icons.gavel_outlined), label: Text('Disputes')),
                  NavigationRailDestination(icon: Icon(Icons.history), label: Text('Audit')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    _StaffBar(role: role),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _paths = [
  AdminRouteNames.users,
  AdminRouteNames.verification,
  AdminRouteNames.orders,
  AdminRouteNames.revenue,
  AdminRouteNames.coupons,
  AdminRouteNames.disputes,
  AdminRouteNames.audit,
];

int _index(String path) {
  final match = _paths.indexWhere((item) => path == item || path.startsWith('$item/'));
  return match < 0 ? 0 : match;
}

class _StaffBar extends ConsumerWidget {
  const _StaffBar({required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      child: ListTile(
        title: const Text('MechUpp Admin'),
        subtitle: Text('Signed in as $role'),
        trailing: DropdownButton<String>(
          value: role,
          items: const [
            DropdownMenuItem(value: 'support', child: Text('support')),
            DropdownMenuItem(value: 'admin', child: Text('admin')),
          ],
          onChanged: (value) {
            if (value != null) ref.read(adminRoleProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}
