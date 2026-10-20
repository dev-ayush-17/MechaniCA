import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_states.dart';
import '../domain/review.dart';

class MechanicReviewsScreen extends ConsumerWidget {
  const MechanicReviewsScreen({super.key, required this.mechanicId});

  final String mechanicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MechanicReviewPage>(
      future: _load(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorState(message: 'Could not load reviews'),
          );
        }
        final page = snapshot.data!;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Reviews')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                page.ratingLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${page.ratingCount} reviews',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              for (final review in page.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${review.stars} / 5', style: const TextStyle(color: Colors.white)),
                        if (review.text.isNotEmpty)
                          Text(review.text, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<MechanicReviewPage> _load(WidgetRef ref) async {
    final result = await ref.read(reviewRepositoryProvider).listForMechanic(mechanicId);
    return result.when(
      onOk: (page) => page,
      onErr: (failure) => throw Exception(failure.message),
    );
  }
}
