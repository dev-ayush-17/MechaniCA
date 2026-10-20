import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../composition/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/shared/app_states.dart';
import '../../widgets/shared/app_widgets.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactsControllerProvider.notifier).load();
    });
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add contact', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(hint: 'Name', controller: name, label: 'Name'),
            const SizedBox(height: 8),
            AppTextField(
              hint: '9876543210',
              controller: phone,
              label: 'Mobile',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final error = await ref.read(contactsControllerProvider.notifier).add(
          name: name.text,
          phone: phone.text,
        );
    if (!mounted) return;
    showAppSnackbar(context, error ?? 'Contact saved', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: _add)],
      ),
      body: state.items.isEmpty
          ? const EmptyState(
              icon: Icons.contact_phone_outlined,
              title: 'No emergency contacts',
              subtitle: 'Add up to 3 people for tracking share',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (_, i) {
                final contact = state.items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.primaryRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text(contact.phoneE164, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () =>
                            ref.read(contactsControllerProvider.notifier).remove(contact.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
