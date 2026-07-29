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

// ─── WALLET SCREEN ────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).load('usr_001');
    });
  }

  IconData _txnIcon(String type) {
    switch (type) {
      case 'cashback': return Icons.percent_rounded;
      case 'referral': return Icons.people_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'topup': return Icons.add_rounded;
      case 'refund': return Icons.undo_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet')),
      body: wallet.isLoading
          ? const ShimmerList()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Balance Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1C0808), Color(0xFF2A1010)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                          boxShadow: AppShadows.red,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('₹${wallet.balance.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: '+ Add Money',
                                    height: 44,
                                    onPressed: () => context.push(RouteNames.addMoney),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Redeem',
                                    isOutlined: true,
                                    height: 44,
                                    onPressed: () => showAppSnackbar(context, 'No points to redeem yet'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),

                      // Cashback + Points row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _StatCard2('1,250', 'Loyalty Points', Icons.star_rounded, AppColors.gold)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard2('₹350', 'Total Cashback', Icons.percent_rounded, AppColors.success)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Transactions'),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final txn = wallet.transactions[i];
                      final icon = _txnIcon(txn.type);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (txn.isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, size: 20, color: txn.isCredit ? AppColors.success : AppColors.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(txn.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(txn.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${txn.isCredit ? '+' : '-'}₹${txn.amount.toInt()}',
                                  style: TextStyle(
                                    color: txn.isCredit ? AppColors.success : AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${txn.date.day} May',
                                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
                    },
                    childCount: wallet.transactions.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard2(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ADD MONEY SCREEN ─────────────────────────────────────────────────────────

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});
  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  double _amount = 500;
  bool _isLoading = false;
  final _ctrl = TextEditingController(text: '500');

  final _presets = [200, 500, 1000, 2000];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Money'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Enter amount',
              controller: _ctrl,
              keyboardType: TextInputType.number,
              prefix: const Padding(padding: EdgeInsets.all(14), child: Text('₹', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: _presets.map((p) => GestureDetector(
                onTap: () {
                  _ctrl.text = '$p';
                  setState(() => _amount = p.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _amount == p ? AppColors.primaryRed.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _amount == p ? AppColors.primaryRed : AppColors.divider),
                  ),
                  child: Text('₹$p', style: TextStyle(color: _amount == p ? AppColors.primaryRed : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Pay via UPI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...[('Google Pay', Icons.payments_outlined), ('PhonePe', Icons.phone_android_rounded), ('Paytm', Icons.account_balance_wallet_outlined)].map((m) =>
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(m.$2, color: AppColors.primaryRed, size: 22),
                  const SizedBox(width: 12),
                  Text(m.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
                ]),
              ),
            ).toList(),
            const Spacer(),
            AppButton(
              label: 'Add ₹${_amount.toInt()} to Wallet',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                await ref.read(walletProvider.notifier).addMoney('usr_001', _amount);
                if (mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, '₹${_amount.toInt()} added to wallet!');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
