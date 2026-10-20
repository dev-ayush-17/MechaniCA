import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/inbox_notification.dart';
import '../domain/notification_inbox.dart';

class NotificationsController
    extends StateNotifier<AsyncValue<List<InboxNotification>>> {
  NotificationsController(this._inbox) : super(const AsyncLoading());

  final NotificationInbox _inbox;

  Future<void> load() async {
    state = const AsyncLoading();
    final result = await _inbox.list();
    state = result.when(
      onOk: (items) => AsyncData(items),
      onErr: (failure) => AsyncError(failure.message, StackTrace.current),
    );
  }

  Future<void> markRead(String id) async {
    final result = await _inbox.markRead(id);
    result.when(
      onOk: (updated) {
        state.whenData((list) {
          state = AsyncData(
            list.map((item) => item.id == updated.id ? updated : item).toList(),
          );
        });
      },
      onErr: (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
    );
  }

  Future<void> markAllRead() async {
    final unread = state.whenOrNull(
          data: (list) => list
              .where((item) => !item.isRead)
              .map((item) => item.id)
              .toList(),
        ) ??
        const <String>[];
    final result = await _inbox.markAllRead(unread);
    result.when(
      onOk: (_) {
        state.whenData((list) {
          state = AsyncData(
              list.map((item) => item.copyWith(isRead: true)).toList());
        });
      },
      onErr: (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
    );
  }

  Future<void> delete(String id) async {
    final result = await _inbox.delete(id);
    result.when(
      onOk: (_) {
        state.whenData((list) {
          state = AsyncData(list.where((item) => item.id != id).toList());
        });
      },
      onErr: (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
    );
  }
}
