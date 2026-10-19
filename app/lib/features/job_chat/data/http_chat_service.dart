import 'package:dio/dio.dart';

import '../../../core/api/generated/messages/messages_client.dart';
import '../../../core/api/generated/models/send_message_request.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/chat_message.dart';
import '../domain/chat_service.dart';

class HttpChatService implements ChatService {
  HttpChatService({
    required MessagesClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final MessagesClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<ChatMessage>> send({
    required String bookingId,
    required String text,
    String? mediaPath,
    String? idempotencyKey,
  }) async {
    try {
      final token = await _token();
      final body = await _client.sendMessageV1BookingsBookingIdMessagesPost(
        bookingId: bookingId,
        body: SendMessageRequest(text: text, mediaPath: mediaPath),
        idempotencyKey: idempotencyKey,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_fromApi(body.id, body.bookingId, body.senderId, body.senderRole,
          body.text, body.mediaPath, body.createdAt, body.state));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> list(String bookingId, {DateTime? after}) async {
    try {
      final token = await _token();
      final body = await _client.listMessagesV1BookingsBookingIdMessagesGet(
        bookingId: bookingId,
        after: after,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok([
        for (final item in body.items)
          _fromApi(item.id, item.bookingId, item.senderId, item.senderRole,
              item.text, item.mediaPath, item.createdAt, item.state),
      ]);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}

ChatMessage _fromApi(
  String id,
  String bookingId,
  String senderId,
  String senderRole,
  String? text,
  String? mediaPath,
  DateTime createdAt,
  String state,
) {
  return ChatMessage(
    id: id,
    bookingId: bookingId,
    senderId: senderId,
    senderRole: senderRole,
    text: text,
    mediaPath: mediaPath,
    createdAt: createdAt,
    state: switch (state) {
      'sending' => ChatMessageState.sending,
      'failed' => ChatMessageState.failed,
      _ => ChatMessageState.sent,
    },
  );
}
