// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_list_out.dart';
import '../models/notification_out.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) = _NotificationsClient;

  /// List Notifications
  @GET('/v1/notifications')
  Future<NotificationListOut> listNotificationsV1NotificationsGet({
    @Header('authorization') String? authorization,
  });

  /// Delete Notification
  @DELETE('/v1/notifications/{notification_id}')
  Future<void> deleteNotificationV1NotificationsNotificationIdDelete({
    @Path('notification_id') required String notificationId,
    @Header('authorization') String? authorization,
  });

  /// Mark Read
  @POST('/v1/notifications/{notification_id}/read')
  Future<NotificationOut> markReadV1NotificationsNotificationIdReadPost({
    @Path('notification_id') required String notificationId,
    @Header('authorization') String? authorization,
  });
}
