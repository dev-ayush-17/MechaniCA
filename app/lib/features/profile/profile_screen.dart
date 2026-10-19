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

// ─── PROFILE SCREEN ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = mockUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.bikeCardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 38, backgroundColor: AppColors.primaryRed, child: Text(u.name[0], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
                      Positioned(bottom: 0, right: 0, child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                      )),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(u.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                          const SizedBox(width: 4),
                          Text('${u.membershipPlan} Member', style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.primaryRed), onPressed: () => context.push(RouteNames.editProfile)),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatCard3('8', 'Bookings', Icons.build_rounded),
                const SizedBox(width: 8),
                _StatCard3('₹2,150', 'Saved', Icons.percent_rounded),
                const SizedBox(width: 8),
                _StatCard3('4.9★', 'Rating', Icons.star_rounded),
              ],
            ),

            const SizedBox(height: 20),

            // Menu sections
            _MenuSection('Account', [
              _MenuItem('Edit Profile', Icons.person_outline, () => context.push(RouteNames.editProfile)),
              _MenuItem('My Addresses', Icons.location_on_outlined, () => context.push(RouteNames.addresses)),
              _MenuItem('Documents', Icons.description_outlined, () => context.push(RouteNames.documents)),
            ]),
            const SizedBox(height: 12),
            _MenuSection('Features', [
              _MenuItem('Service History', Icons.history_rounded, () => context.go(RouteNames.history)),
              _MenuItem('Fuel Tracker', Icons.local_gas_station_rounded, () => context.push(RouteNames.fuelTracker)),
              _MenuItem('Health Score', Icons.favorite_rounded, () => context.push(RouteNames.healthScore)),
              _MenuItem('Refer & Earn', Icons.people_rounded, () => context.push(RouteNames.referEarn)),
              _MenuItem('Membership', Icons.star_rounded, () => context.push(RouteNames.membership)),
            ]),
            const SizedBox(height: 12),
            _MenuSection('Settings', [
              _MenuItem('App Settings', Icons.settings_rounded, () => context.push(RouteNames.settings)),
              _MenuItem('Support', Icons.support_agent_rounded, () => context.push(RouteNames.support)),
              _MenuItem('Rate the App', Icons.thumb_up_rounded, () => showAppSnackbar(context, 'Thanks for the feedback!')),
              _MenuItem('Logout', Icons.logout_rounded, () => _logout(context, ref), color: AppColors.error),
            ]),
            const SizedBox(height: 24),
            const Text('MechaniCA v1.0.0', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(RouteNames.login);
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatCard3 extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard3(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

Widget _MenuSection(String title, List<Widget> items) {
  return Container(
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        ...items,
      ],
    ),
  );
}

Widget _MenuItem(String label, IconData icon, VoidCallback onTap, {Color? color}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14))),
          Icon(Icons.chevron_right, size: 16, color: color ?? AppColors.textTertiary),
        ],
      ),
    ),
  );
}

// ─── EDIT PROFILE SCREEN ──────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: mockUser.name);
    _emailCtrl = TextEditingController(text: mockUser.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 46, backgroundColor: AppColors.primaryRed, child: Text(mockUser.name[0], style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
                  Positioned(bottom: 0, right: 0, child: GestureDetector(
                    onTap: () => showAppSnackbar(context, 'Upload photo feature coming soon'),
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)), child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(hint: 'Full Name', controller: _nameCtrl, label: 'Full Name'),
            const SizedBox(height: 16),
            AppTextField(hint: 'Email', controller: _emailCtrl, label: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            AppTextField(hint: mockUser.phone, label: 'Phone (Cannot be changed)', readOnly: true),
            const Spacer(),
            AppButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 1000));
                if (mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, 'Profile updated successfully!');
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

// ─── ADDRESSES SCREEN ─────────────────────────────────────────────────────────

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Addresses'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () {})],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockAddresses.length,
        itemBuilder: (_, i) {
          final a = mockAddresses[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: a.isDefault ? Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.label == 'Home' ? Icons.home_rounded : a.label == 'Work' ? Icons.work_rounded : Icons.location_on_rounded, color: AppColors.primaryRed, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(a.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        if (a.isDefault) ...[const SizedBox(width: 8), const StatusBadge(label: 'Default', color: AppColors.primaryRed)],
                      ]),
                      const SizedBox(height: 4),
                      Text(a.fullAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  onSelected: (v) => showAppSnackbar(context, v == 'delete' ? 'Address deleted' : 'Address edited'),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── SETTINGS SCREEN ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = true;
  bool _smsAlerts = true;
  bool _offerNotifs = true;
  bool _darkMode = true;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection('Notifications', [
            _Toggle('Push Notifications', _notifs, (v) => setState(() => _notifs = v)),
            _Toggle('SMS Alerts', _smsAlerts, (v) => setState(() => _smsAlerts = v)),
            _Toggle('Offer Notifications', _offerNotifs, (v) => setState(() => _offerNotifs = v)),
          ]),
          const SizedBox(height: 16),
          _SettingsSection('Appearance', [
            _Toggle('Dark Mode', _darkMode, (v) => setState(() => _darkMode = v)),
          ]),
          const SizedBox(height: 16),
          _SettingsSection('Security', [
            _Toggle('Biometric Login', _biometrics, (v) => setState(() => _biometrics = v)),
          ]),
          const SizedBox(height: 16),
          _SettingsSection('Data', [
            _SettingRow('Clear Cache', Icons.delete_outline, () => showAppSnackbar(context, 'Cache cleared!')),
            _SettingRow('Export Data', Icons.download_outlined, () => showAppSnackbar(context, 'Data export started')),
            _SettingRow('Delete Account', Icons.delete_forever_rounded, () {}, color: AppColors.error),
          ]),
        ],
      ),
    );
  }
}

Widget _SettingsSection(String title, List<Widget> items) {
  return Container(
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        ...items,
      ],
    ),
  );
}

Widget _Toggle(String label, bool value, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primaryRed),
      ],
    ),
  );
}

Widget _SettingRow(String label, IconData icon, VoidCallback onTap, {Color? color}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
        ],
      ),
    ),
  );
}
