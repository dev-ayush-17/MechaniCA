import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_states.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../domain/pricing.dart';
import '../domain/repeat_prefill.dart';

class ServiceStep extends ConsumerWidget {
  const ServiceStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(catalogServicesProvider);
    final flow = ref.watch(bookingFlowProvider);

    return Column(
      children: [
        Expanded(
          child: servicesAsync.when(
            loading: () => const ShimmerList(),
            error: (_, __) => const Center(child: Text('Failed to load services')),
            data: (snapshot) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'Updated ${DateFormat.jm().format(snapshot.updatedAt!.toLocal())}.',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.services.length,
                    itemBuilder: (_, i) {
                      final svc = snapshot.services[i];
                      final selected = flow.selectedService?.id == svc.code;
                      return GestureDetector(
                        onTap: () => ref
                            .read(bookingFlowProvider.notifier)
                            .selectService(serviceModelFromDefinition(svc)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryRed
                                  : AppColors.divider,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.build_rounded,
                                  size: 22,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          svc.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (svc.code == 'general_service') ...[
                                          const SizedBox(width: 8),
                                          const StatusBadge(
                                            label: 'Popular',
                                            color: AppColors.warning,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      svc.description,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      svc.durationLabel,
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatPaise(svc.baseLaborPaise),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (selected)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryRed,
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Next',
            onPressed: flow.selectedService != null ? onNext : null,
          ),
        ),
      ],
    );
  }
}

