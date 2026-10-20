import '../../../core/error/result.dart';
import '../domain/inbox_notification.dart';
import '../domain/notification_inbox.dart';

class FakeNotificationInbox implements NotificationInbox {
  FakeNotificationInbox([List<InboxNotification>? seed])
      : items = List.of(seed ?? const []);

  final List<InboxNotification> items;

  static const markReadBatchSize = 50;

  @override
  Future<Result<List<InboxNotification>>> list() async {
    final copy = List<InboxNotification>.of(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Ok(copy);
  }

  @override
  Future<Result<InboxNotification>> markRead(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const Err(NotFound('We could not find that notification.'));
    }
    final updated = items[index].copyWith(isRead: true);
    items[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    items.removeWhere((item) => item.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> markAllRead(List<String> ids) async {
    for (var i = 0; i < ids.length; i += markReadBatchSize) {
      final end = i + markReadBatchSize > ids.length
          ? ids.length
          : i + markReadBatchSize;
      final batch = ids.sublist(i, end);
      for (final id in batch) {
        await markRead(id);
      }
    }
    return const Ok(null);
  }
}
