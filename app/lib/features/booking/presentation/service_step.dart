import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/service_model.dart';
import '../../../widgets/shared/app_states.dart';
import '../../../widgets/shared/app_widgets.dart';
import '../../catalog/domain/service_definition.dart';
import '../domain/pricing.dart';

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
            data: (services) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (_, i) {
                final svc = services[i];
                final selected = flow.selectedService?.id == svc.code;
                return GestureDetector(
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .selectService(_toServiceModel(svc)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primaryRed : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
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

ServiceModel _toServiceModel(ServiceDefinition svc) {
  return ServiceModel(
    id: svc.code,
    name: svc.name,
    description: svc.description,
    price: (svc.baseLaborPaise ~/ 100).toDouble(),
    iconName: 'build',
    category: 'service',
    duration: svc.durationLabel,
    isPopular: svc.code == 'general_service',
    includes: const [],
  );
}
