import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/admin_models.dart';
import 'admin_providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<AdminUserRow> _items = const [];
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).searchUsers(_query.text);
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final canAct = canRefund(ref.watch(adminRoleProvider));
    return _Pane(
      title: 'Users',
      child: Column(
        children: [
          TextField(
            controller: _query,
            decoration: const InputDecoration(hintText: 'Search phone or name'),
            onSubmitted: (_) => _load(),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final user in _items)
                  ListTile(
                    title: Text(user.name),
                    subtitle: Text('${user.phone} · ${user.status}'),
                    trailing: canAct && user.status != 'suspended'
                        ? TextButton(
                            onPressed: () async {
                              await ref.read(adminApiProvider).suspendUser(user.id, reason: 'Admin hold');
                              await _load();
                            },
                            child: const Text('Suspend'),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  List<AdminApplicationRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).listApplications();
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final canAct = canRefund(ref.watch(adminRoleProvider));
    return _Pane(
      title: 'Verification',
      child: ListView(
        children: [
          for (final item in _items)
            ListTile(
              title: Text(item.displayName),
              subtitle: Text(item.status),
              trailing: canAct
                  ? TextButton(
                      onPressed: () async {
                        await ref.read(adminApiProvider).decideVerification(item.id, approve: true);
                        await _load();
                      },
                      child: const Text('Approve'),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<AdminBookingRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final result = await ref.read(adminApiProvider).listBookings();
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return _Pane(
      title: 'Orders',
      child: ListView(
        children: [
          for (final item in _items)
            ListTile(
              title: Text(item.displayNumber),
              subtitle: Text('${item.status} · ${item.city}'),
              trailing: Text('₹${item.totalPaise / 100}'),
            ),
        ],
      ),
    );
  }
}

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  AdminRevenue? _report;
  String _window = 'today';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).revenue(_window);
    result.when(onOk: (report) => setState(() => _report = report), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return _Pane(
      title: 'Revenue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final window in const ['today', '7d', '30d'])
                ChoiceChip(
                  label: Text(window),
                  selected: _window == window,
                  onSelected: (_) {
                    setState(() => _window = window);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (report != null) ...[
            Text('GMV ₹${report.gmvPaise / 100}'),
            Text('Refunds ₹${report.refundsPaise / 100}'),
            Text('Cash ₹${report.cashPaise / 100} · Online ₹${report.onlinePaise / 100}'),
            Text('Jobs ${report.jobCount}'),
          ],
        ],
      ),
    );
  }
}

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  List<AdminCouponRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).listCoupons();
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final canAct = canRefund(ref.watch(adminRoleProvider));
    return _Pane(
      title: 'Coupons',
      child: ListView(
        children: [
          if (canAct)
            ListTile(
              title: const Text('Create NEW50'),
              onTap: () async {
                await ref.read(adminApiProvider).createCoupon(code: 'NEW50', title: 'New 50');
                await _load();
              },
            ),
          for (final item in _items)
            ListTile(
              title: Text(item.code),
              subtitle: Text('${item.title} · redemptions ${item.redemptionCount}'),
              trailing: canAct && item.active
                  ? TextButton(
                      onPressed: () async {
                        await ref.read(adminApiProvider).disableCoupon(item.code);
                        await _load();
                      },
                      child: const Text('Disable'),
                    )
                  : Text(item.active ? 'active' : 'off'),
            ),
        ],
      ),
    );
  }
}

class DisputesScreen extends ConsumerStatefulWidget {
  const DisputesScreen({super.key});

  @override
  ConsumerState<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends ConsumerState<DisputesScreen> {
  List<AdminDisputeRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).listDisputes();
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final canAct = canRefund(ref.watch(adminRoleProvider));
    return _Pane(
      title: 'Disputes',
      child: ListView(
        children: [
          for (final item in _items)
            ListTile(
              title: Text(item.reason),
              subtitle: Text(item.bookingId),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => ref.read(adminApiProvider).addDisputeNote(item.id, note: 'Noted'),
                    child: const Text('Note'),
                  ),
                  if (canAct)
                    TextButton(
                      onPressed: () async {
                        await ref.read(adminApiProvider).resolveDispute(
                              item.id,
                              resolution: 'no_refund',
                              amountPaise: 0,
                              note: 'Closed',
                            );
                        await _load();
                      },
                      child: const Text('Resolve'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  List<AdminAuditRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(adminApiProvider).listAudit();
    result.when(onOk: (items) => setState(() => _items = items), onErr: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return _Pane(
      title: 'Audit',
      child: ListView(
        children: [
          for (final item in _items)
            ListTile(title: Text(item.action), subtitle: Text('${item.targetId} · ${item.summary}')),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
