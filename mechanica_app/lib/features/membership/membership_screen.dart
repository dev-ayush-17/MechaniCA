import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── MEMBERSHIP SCREEN ────────────────────────────────────────────────────────

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(membershipPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Membership Plans'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: plansAsync.when(
        loading: () => const ShimmerList(),
        error: (_, __) => const ErrorState(message: 'Failed to load plans'),
        data: (plans) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Current plan banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.gold.withValues(alpha: 0.15), AppColors.cardBackground]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.gold, size: 32),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gold Member', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Active until Dec 2024', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    const StatusBadge(label: 'Active', color: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...plans.asMap().entries.map((e) {
                final plan = e.value;
                final planColor = Color(int.parse(plan.badgeColor.replaceFirst('#', '0xFF')));
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [planColor.withValues(alpha: 0.1), AppColors.cardBackground]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: planColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: planColor, size: 28),
                          const SizedBox(width: 8),
                          Text(plan.name, style: TextStyle(color: planColor, fontSize: 20, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('₹${plan.price.toInt()}', style: TextStyle(color: planColor, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text(plan.duration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...plan.benefits.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 15),
                          const SizedBox(width: 8),
                          Text(b, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ]),
                      )).toList(),
                      const SizedBox(height: 16),
                      AppButton(
                        label: mockUser.membershipPlan.toLowerCase() == plan.name.toLowerCase()
                            ? 'Current Plan'
                            : 'Upgrade to ${plan.name}',
                        color: mockUser.membershipPlan.toLowerCase() == plan.name.toLowerCase() ? AppColors.surfaceElevated : null,
                        onPressed: mockUser.membershipPlan.toLowerCase() == plan.name.toLowerCase()
                            ? null
                            : () async {
                                await ref.read(membershipRepositoryProvider).upgradeMembership('usr_001', plan.id);
                                if (context.mounted) context.push(RouteNames.purchaseSuccess, extra: plan.name);
                              },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: e.key * 100));
              }).toList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PURCHASE SUCCESS SCREEN ──────────────────────────────────────────────────

class PurchaseSuccessScreen extends StatelessWidget {
  final String planName;
  const PurchaseSuccessScreen({super.key, required this.planName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.star_rounded, size: 60, color: AppColors.gold),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              Text('Welcome to $planName!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              const Text('Your membership is now active. Enjoy exclusive benefits!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              AppButton(label: 'Back to Home', onPressed: () => context.go(RouteNames.home)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── REFER & EARN SCREEN ──────────────────────────────────────────────────────

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1C1C30), AppColors.cardBackground]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.people_rounded, size: 64, color: AppColors.primaryRed),
                  const SizedBox(height: 16),
                  const Text('Invite friends & get rewards!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Earn ₹150 for every friend who books their first service', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(mockUser.referralCode, style: const TextStyle(color: AppColors.primaryRed, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3)),
                        GestureDetector(
                          onTap: () => showAppSnackbar(context, 'Code copied!'),
                          child: const Icon(Icons.copy_rounded, color: AppColors.primaryRed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(label: 'Share Now', icon: Icons.share_rounded, onPressed: () => showAppSnackbar(context, 'Sharing...')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Earnings summary
            Row(
              children: [
                Expanded(child: _ReferStat('₹350', 'Your Savings')),
                const SizedBox(width: 12),
                Expanded(child: _ReferStat('12', 'Friends Joined')),
              ],
            ),
            const SizedBox(height: 24),
            // How it works
            const Text('How it Works', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[
              ('Share your referral code', Icons.share_rounded),
              ('Friend signs up & books a service', Icons.motorcycle_rounded),
              ('You earn ₹150 in your wallet', Icons.account_balance_wallet_rounded),
            ].asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value.$1, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Icon(e.value.$2, color: AppColors.primaryRed, size: 20),
                ],
              ),
            )).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ReferStat extends StatelessWidget {
  final String value;
  final String label;
  const _ReferStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
