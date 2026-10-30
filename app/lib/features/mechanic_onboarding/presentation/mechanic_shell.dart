import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import 'mechanic_session_ticker.dart';

class MechanicShell extends ConsumerStatefulWidget {
  const MechanicShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends ConsumerState<MechanicShell> {
  bool _openingOffer = false;

  static const _tabs = [
    MechanicRouteNames.home,
    MechanicRouteNames.jobs,
    MechanicRouteNames.profile,
  ];

  int _tabIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i] || location.startsWith('${_tabs[i]}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mechanicSessionTickerProvider, (previous, next) {
      final offerId = next.pendingOfferId;
      if (offerId != null &&
          offerId != previous?.pendingOfferId &&
          !_openingOffer) {
        _openingOffer = true;
        ref.read(mechanicSessionTickerProvider.notifier).consumeOffer();
        context.push(MechanicRouteNames.offerPath(offerId)).whenComplete(() {
          _openingOffer = false;
        });
      }
    });

    final index = _tabIndex(context);
    final pending = ref.watch(mechanicSessionTickerProvider).pendingOfferId;

    return Scaffold(
      body: widget.child,
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
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: index == 0,
                  onTap: () => context.go(MechanicRouteNames.home),
                ),
                _NavItem(
                  icon: Icons.handyman_rounded,
                  label: 'Jobs',
                  selected: index == 1,
                  onTap: () => context.go(MechanicRouteNames.jobs),
                  badgeCount: pending != null ? 1 : null,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: index == 2,
                  onTap: () => context.go(MechanicRouteNames.profile),
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
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryRed.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primaryRed : AppColors.textTertiary,
                ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
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
