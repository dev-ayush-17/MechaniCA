import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/route_names.dart';
import '../../../widgets/shared/app_states.dart';
import '../domain/parts_proof.dart';

/// Customer view of server-stored parts proofs. Keeps the inspection
/// before/after layout and adds the old-part row (FR-MEC-008).
class CustomerProofsScreen extends ConsumerWidget {
  const CustomerProofsScreen({
    super.key,
    required this.bookingId,
    this.seed,
  });

  final String bookingId;
  final List<PartsProof>? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (seed != null) {
      return _body(context, seed!);
    }
    final token = ref.watch(authProvider).session?.idToken ?? '';
    return FutureBuilder<List<PartsProof>>(
      future: _load(ref, token),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorState(message: 'Failed to load inspection'),
          );
        }
        return _body(context, snapshot.data ?? const []);
      },
    );
  }

  Future<List<PartsProof>> _load(WidgetRef ref, String token) async {
    final result = await ref.read(partsProofRepositoryProvider).list(
          token: token,
          bookingId: bookingId,
        );
    return result.when(onOk: (items) => items, onErr: (_) => const []);
  }

  Scaffold _body(BuildContext context, List<PartsProof> proofs) {
    List<String> urls(ProofKind kind) => proofs
        .where((item) => item.kind == kind && !item.hidden)
        .map((item) => item.uploadUrl ?? item.path)
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Inspection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(context, 'Before Service', urls(ProofKind.before)),
            const SizedBox(height: 20),
            _section(context, 'After Service', urls(ProofKind.after)),
            const SizedBox(height: 20),
            _section(context, 'Old part', urls(ProofKind.oldPart)),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push(RouteNames.inspectionMock, extra: bookingId),
                child: const Text('Debug: open demo inspection'),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          Container(
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No photos yet', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: photos.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => context.push(
                RouteNames.photoGallery,
                extra: {'photos': photos, 'index': i},
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photos[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 36),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
