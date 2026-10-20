import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../composition/providers.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── PROFILE SCREEN ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider).account;
    final name = (account?.name.isNotEmpty ?? false) ? account!.name : 'Your profile';
    final phone = account?.phoneE164 ?? '';
    final accountRole = account?.role;
    final bookings = ref.watch(homeBookingsProvider).whenOrNull(data: (list) => list.length) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (accountRole == 'mechanic')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'This phone is registered as a mechanic account. '
                  'Open the MechUpp Mechanic app to go online and take jobs.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.bikeCardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 38, backgroundColor: AppColors.primaryRed, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
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
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 6),
                        const Row(children: [
                          Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                          SizedBox(width: 4),
                          Text('MechUpp Member', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
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
                _StatCard3('$bookings', 'Bookings', Icons.build_rounded),
                const SizedBox(width: 8),
                const _StatCard3('—', 'Saved', Icons.percent_rounded),
                const SizedBox(width: 8),
                const _StatCard3('—', 'Rating', Icons.star_rounded),
              ],
            ),

            const SizedBox(height: 20),

            // Menu sections
            _menuSection('Account', [
              _menuItem('Edit Profile', Icons.person_outline, () => context.push(RouteNames.editProfile)),
              _menuItem('My Addresses', Icons.location_on_outlined, () => context.push(RouteNames.addresses)),
              _menuItem('Emergency Contacts', Icons.contact_phone_outlined, () => context.push(RouteNames.emergencyContacts)),
              _menuItem('Documents', Icons.description_outlined, () => context.push(RouteNames.documents)),
            ]),
            const SizedBox(height: 12),
            _menuSection('Features', [
              _menuItem('Service History', Icons.history_rounded, () => context.go(RouteNames.history)),
              _menuItem('Fuel Tracker', Icons.local_gas_station_rounded, () => context.push(RouteNames.fuelTracker)),
              _menuItem('Health Score', Icons.favorite_rounded, () => context.push(RouteNames.healthScore)),
              _menuItem('Refer & Earn', Icons.people_rounded, () => context.push(RouteNames.referEarn)),
              _menuItem('Membership', Icons.star_rounded, () => context.push(RouteNames.membership)),
            ]),
            const SizedBox(height: 12),
            _menuSection('Settings', [
              _menuItem('App Settings', Icons.settings_rounded, () => context.push(RouteNames.settings)),
              _menuItem('Support', Icons.support_agent_rounded, () => context.push(RouteNames.support)),
              _menuItem('Rate the App', Icons.thumb_up_rounded, () => showAppSnackbar(context, 'Thanks for the feedback!')),
              _menuItem('Logout', Icons.logout_rounded, () => _logout(context, ref), color: AppColors.error),
            ]),
            const SizedBox(height: 24),
            const Text('MechUpp v1.0.0', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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

Widget _menuSection(String title, List<Widget> items) {
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

Widget _menuItem(String label, IconData icon, VoidCallback onTap, {Color? color}) {
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
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = ref.read(authProvider).account;
    _nameCtrl = TextEditingController(text: account?.name ?? '');
    _emailCtrl = TextEditingController(text: account?.email ?? '');
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
                  CircleAvatar(radius: 46, backgroundColor: AppColors.primaryRed, child: Text((_nameCtrl.text.isEmpty ? 'U' : _nameCtrl.text[0]).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
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
            AppTextField(
              hint: ref.watch(authProvider).account?.phoneE164 ?? '',
              label: 'Phone (Cannot be changed)',
              readOnly: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const Spacer(),
            AppButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.length < 2 || name.length > 60) {
                  setState(() => _error = 'Name must be 2 to 60 characters.');
                  return;
                }
                final session = ref.read(authProvider).session;
                if (session == null) {
                  setState(() => _error = 'Sign in again.');
                  return;
                }
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                final result = await ref.read(accountApiProvider).update(
                      session,
                      name: name,
                      email: _emailCtrl.text.trim(),
                    );
                if (!mounted) return;
                result.when(
                  onOk: (account) {
                    ref.read(authProvider.notifier).applyAccount(account);
                    setState(() => _isLoading = false);
                    showAppSnackbar(context, 'Profile updated successfully!');
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  onErr: (failure) => setState(() {
                    _isLoading = false;
                    _error = failure.message;
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ADDRESSES SCREEN ─────────────────────────────────────────────────────────

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});
  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressesControllerProvider.notifier).load();
    });
  }

  Future<void> _add() async {
    final label = TextEditingController(text: 'Home');
    final line1 = TextEditingController();
    final city = TextEditingController(text: 'Patna');
    final pin = TextEditingController();
    final landmark = TextEditingController();
    final lat = TextEditingController(text: '25.5941');
    final lng = TextEditingController(text: '85.1376');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add address', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(hint: 'Home', controller: label, label: 'Label'),
              const SizedBox(height: 8),
              AppTextField(hint: 'Street', controller: line1, label: 'Address line'),
              const SizedBox(height: 8),
              AppTextField(hint: 'Landmark', controller: landmark, label: 'Landmark'),
              const SizedBox(height: 8),
              AppTextField(hint: 'Patna', controller: city, label: 'City'),
              const SizedBox(height: 8),
              AppTextField(hint: '800001', controller: pin, label: 'PIN', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              AppTextField(hint: '25.5941', controller: lat, label: 'Latitude', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              AppTextField(hint: '85.1376', controller: lng, label: 'Longitude', keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final error = await ref.read(addressesControllerProvider.notifier).add(
          label: label.text,
          line1: line1.text,
          city: city.text,
          pincode: pin.text,
          lat: double.tryParse(lat.text) ?? 25.5941,
          lng: double.tryParse(lng.text) ?? 85.1376,
          landmark: landmark.text,
        );
    if (!mounted) return;
    showAppSnackbar(context, error ?? 'Address saved', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressesControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Addresses'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: _add)],
      ),
      body: state.items.isEmpty
          ? const EmptyState(icon: Icons.location_off_outlined, title: 'No addresses', subtitle: 'Add a home or work address')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (_, i) {
                final a = state.items[i];
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
                        onSelected: (v) {
                          if (v == 'delete') {
                            ref.read(addressesControllerProvider.notifier).remove(a.id);
                          }
                        },
                        itemBuilder: (_) => [
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
          _settingsSection('Notifications', [
            _toggle('Push Notifications', _notifs, (v) => setState(() => _notifs = v)),
            _toggle('SMS Alerts', _smsAlerts, (v) => setState(() => _smsAlerts = v)),
            _toggle('Offer Notifications', _offerNotifs, (v) => setState(() => _offerNotifs = v)),
          ]),
          const SizedBox(height: 16),
          _settingsSection('Appearance', [
            _toggle('Dark Mode', _darkMode, (v) => setState(() => _darkMode = v)),
          ]),
          const SizedBox(height: 16),
          _settingsSection('Security', [
            _toggle('Biometric Login', _biometrics, (v) => setState(() => _biometrics = v)),
          ]),
          const SizedBox(height: 16),
          _settingsSection('Data', [
            _settingRow('Clear Cache', Icons.delete_outline, () => showAppSnackbar(context, 'Cache cleared!')),
            _settingRow('Export Data', Icons.download_outlined, () => showAppSnackbar(context, 'Data export started')),
            _settingRow('Delete Account', Icons.delete_forever_rounded, () {}, color: AppColors.error),
          ]),
        ],
      ),
    );
  }
}

Widget _settingsSection(String title, List<Widget> items) {
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

Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.primaryRed),
      ],
    ),
  );
}

Widget _settingRow(String label, IconData icon, VoidCallback onTap, {Color? color}) {
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
