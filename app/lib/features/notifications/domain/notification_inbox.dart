import '../../../core/error/result.dart';
import 'inbox_notification.dart';

/// Owner's in-app list. Mark-read and delete go to the API, never Firestore.
abstract interface class NotificationInbox {
  Future<Result<List<InboxNotification>>> list();

  Future<Result<InboxNotification>> markRead(String id);

  Future<Result<void>> delete(String id);

  /// Sends mark-read in batches of 50 (chapter 17).
  Future<Result<void>> markAllRead(List<String> ids);
}
