import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shared/app_states.dart';
import '../domain/inbox_notification.dart';

const kNotificationsEmptyCopy = 'No notifications yet.';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  IconData _typeIcon(String templateId) {
    if (templateId.startsWith('offer')) return Icons.local_offer_rounded;
    if (templateId.startsWith('payment') || templateId == 'cashConfirm') {
      return Icons.account_balance_wallet_rounded;
    }
    if (templateId.contains('Failed') || templateId == 'bookingCancelled') {
      return Icons.sos_rounded;
    }
    return Icons.build_rounded;
  }

  Color _typeColor(String templateId) {
    if (templateId.startsWith('offer')) return AppColors.warning;
    if (templateId.startsWith('payment') || templateId == 'cashConfirm') {
      return AppColors.success;
    }
    if (templateId.contains('Failed') || templateId == 'bookingCancelled') {
      return AppColors.error;
    }
    return AppColors.primaryRed;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _open(InboxNotification item) {
    ref.read(notificationsControllerProvider.notifier).markRead(item.id);
    if (item.deepLink.isEmpty) return;
    final signedIn = ref.read(authProvider).isLoggedIn;
    if (signedIn) {
      context.push(item.deepLink);
      return;
    }
    ref.read(pendingDeepLinkProvider).store(item.deepLink, DateTime.now());
    context.go(ref.read(postOtpRouteProvider));
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationsControllerProvider.notifier)
                .markAllRead(),
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: AppColors.primaryRed, fontSize: 12),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 80),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(notificationsControllerProvider.notifier).load(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: kNotificationsEmptyCopy,
              subtitle: 'You\'re all caught up!',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = notifications[i];
              final color = _typeColor(n.templateId);
              return Dismissible(
                key: Key(n.id),
                onDismissed: (_) => ref
                    .read(notificationsControllerProvider.notifier)
                    .delete(n.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                child: GestureDetector(
                  onTap: () => _open(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? AppColors.cardBackground
                          : color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.isRead
                            ? AppColors.divider
                            : color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon(n.templateId),
                              size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: n.isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _timeAgo(n.createdAt),
                                style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
            },
          );
        },
      ),
    );
  }
}
