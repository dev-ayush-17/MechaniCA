import 'package:dio/dio.dart';

import '../../../core/api/generated/models/notification_out.dart';
import '../../../core/api/generated/notifications/notifications_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/inbox_notification.dart';
import '../domain/notification_inbox.dart';
import 'fake_notification_inbox.dart';

class HttpNotificationInbox implements NotificationInbox {
  HttpNotificationInbox({
    required NotificationsClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final NotificationsClient _client;
  final Future<String?> Function() _token;

  Future<String?> _auth() async {
    final token = await _token();
    return token == null ? null : 'Bearer $token';
  }

  @override
  Future<Result<List<InboxNotification>>> list() async {
    try {
      final body = await _client.listNotificationsV1NotificationsGet(
        authorization: await _auth(),
      );
      return Ok(body.items.map(_fromApi).toList());
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<InboxNotification>> markRead(String id) async {
    try {
      final body = await _client.markReadV1NotificationsNotificationIdReadPost(
        notificationId: id,
        authorization: await _auth(),
      );
      return Ok(_fromApi(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client.deleteNotificationV1NotificationsNotificationIdDelete(
        notificationId: id,
        authorization: await _auth(),
      );
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<void>> markAllRead(List<String> ids) async {
    for (var i = 0;
        i < ids.length;
        i += FakeNotificationInbox.markReadBatchSize) {
      final end = i + FakeNotificationInbox.markReadBatchSize > ids.length
          ? ids.length
          : i + FakeNotificationInbox.markReadBatchSize;
      final batch = ids.sublist(i, end);
      for (final id in batch) {
        final result = await markRead(id);
        final failed = result.when(onOk: (_) => null, onErr: (f) => f);
        if (failed != null) return Err(failed);
      }
    }
    return const Ok(null);
  }
}

InboxNotification _fromApi(NotificationOut item) {
  return InboxNotification(
    id: item.id,
    title: item.title,
    body: item.body,
    templateId: item.templateId,
    deepLink: item.deepLink,
    isRead: item.readAt != null,
    createdAt: item.createdAt,
  );
}
