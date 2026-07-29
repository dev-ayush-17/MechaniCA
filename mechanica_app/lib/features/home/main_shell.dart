import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    RouteNames.home,
    RouteNames.myBikes,
    RouteNames.history,
    RouteNames.wallet,
    RouteNames.profile,
  ];

  int _tabIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _tabIndex(context);
    final unreadCount = ref.watch(notificationProvider).whenOrNull(
              data: (list) => list.where((n) => !n.isRead).length,
            ) ??
        0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', selected: index == 0, onTap: () => context.go(RouteNames.home)),
                _NavItem(icon: Icons.motorcycle_rounded, label: 'My Bikes', selected: index == 1, onTap: () => context.go(RouteNames.myBikes)),
                _NavItem(icon: Icons.history_rounded, label: 'History', selected: index == 2, onTap: () => context.go(RouteNames.history)),
                _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Wallet', selected: index == 3, onTap: () => context.go(RouteNames.wallet)),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: index == 4,
                  onTap: () => context.go(RouteNames.profile),
                  badgeCount: unreadCount > 0 ? unreadCount : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: selected ? AppColors.primaryRed : AppColors.textTertiary),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryRed : AppColors.textTertiary,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
