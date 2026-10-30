import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../navigation/mechanic_route_names.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/mechanic_repository.dart';
import 'mechanic_controller.dart';

class MechanicOnboardingScreen extends ConsumerStatefulWidget {
  const MechanicOnboardingScreen({super.key});

  @override
  ConsumerState<MechanicOnboardingScreen> createState() =>
      _MechanicOnboardingScreenState();
}

class _MechanicOnboardingScreenState
    extends ConsumerState<MechanicOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: '0');
  final _latCtrl = TextEditingController(text: '25.5941');
  final _lngCtrl = TextEditingController(text: '85.1376');
  final _radiusCtrl = TextEditingController(text: '10');
  bool _english = true;
  bool _hindi = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final years = int.tryParse(_yearsCtrl.text.trim()) ?? -1;
    final lat = double.tryParse(_latCtrl.text.trim()) ?? 0;
    final lng = double.tryParse(_lngCtrl.text.trim()) ?? 0;
    final radius = double.tryParse(_radiusCtrl.text.trim()) ?? 0;
    final langs = <String>[
      if (_english) 'en',
      if (_hindi) 'hi',
    ];
    final uid = ref.read(authProvider).account?.id ?? 'mechanic';
    final base = 'mechanicDocs/$uid';
    final input = ApplicationInput(
      displayName: name,
      photoPath: '$base/photo/profile.jpg',
      yearsExperience: years,
      languages: langs,
      serviceArea: ServiceArea(lat: lat, lng: lng, radiusKm: radius),
      documents: {
        MechanicDocumentKind.licence: '$base/licence/licence.pdf',
        MechanicDocumentKind.governmentId: '$base/government_id/id.pdf',
        MechanicDocumentKind.selfie: '$base/selfie/selfie.jpg',
      },
    );
    final ok = await ref.read(mechanicProvider.notifier).submit(input);
    if (!mounted) return;
    if (ok) {
      showAppSnackbar(context, 'Application submitted for review.');
      context.go(MechanicRouteNames.home);
    } else {
      final err = ref.read(mechanicProvider).error;
      if (err != null) showAppSnackbar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mechanic = ref.watch(mechanicProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mechanic application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us about your experience. Documents are uploaded through signed URLs in production; this demo sends placeholder paths.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Years of experience'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _english,
              onChanged: (v) => setState(() => _english = v ?? false),
              title: const Text('English'),
            ),
            CheckboxListTile(
              value: _hindi,
              onChanged: (v) => setState(() => _hindi = v ?? false),
              title: const Text('Hindi'),
            ),
            const Text('Service area (centre + radius km)',
                style: TextStyle(color: AppColors.textSecondary)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Lat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Lng'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Radius (1–20 km)'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: mechanic.isLoading ? 'Submitting…' : 'Submit application',
              onPressed: mechanic.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
