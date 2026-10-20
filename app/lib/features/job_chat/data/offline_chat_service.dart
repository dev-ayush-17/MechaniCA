import 'package:uuid/uuid.dart';

import '../../../core/error/result.dart';
import '../domain/chat_message.dart';
import '../domain/chat_service.dart';

/// Queues text when offline and shows "Waiting to send." (FR-COM-001).
class OfflineChatService implements ChatService {
  OfflineChatService({
    required ChatService remote,
    required bool Function() isOnline,
    Uuid? uuid,
  })  : _remote = remote,
        _isOnline = isOnline,
        _uuid = uuid ?? const Uuid();

  final ChatService _remote;
  final bool Function() _isOnline;
  final Uuid _uuid;
  final List<ChatMessage> queued = [];

  @override
  Future<Result<ChatMessage>> send({
    required String bookingId,
    required String text,
    String? mediaPath,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    if (!_isOnline()) {
      final pending = ChatMessage(
        id: key,
        bookingId: bookingId,
        senderId: 'local',
        senderRole: 'customer',
        text: text,
        mediaPath: mediaPath,
        createdAt: DateTime.now().toUtc(),
        state: ChatMessageState.sending,
      );
      queued.add(pending);
      return Ok(pending);
    }
    return _sendRemote(
      bookingId: bookingId,
      text: text,
      mediaPath: mediaPath,
      key: key,
    );
  }

  @override
  Future<Result<List<ChatMessage>>> list(String bookingId, {DateTime? after}) async {
    final remote = await _remote.list(bookingId, after: after);
    return remote.when(
      onOk: (items) {
        final local = queued.where((m) => m.bookingId == bookingId);
        return Ok([...items, ...local]);
      },
      onErr: Err.new,
    );
  }

  Future<Result<void>> flush() async {
    if (!_isOnline()) return const Ok(null);
    final pending = queued
        .where((m) => m.state == ChatMessageState.sending)
        .toList();
    for (final message in pending) {
      final result = await _sendRemote(
        bookingId: message.bookingId,
        text: message.text ?? '',
        mediaPath: message.mediaPath,
        key: message.id,
      );
      result.when(
        onOk: (_) => queued.removeWhere((m) => m.id == message.id),
        onErr: (_) {
          final i = queued.indexWhere((m) => m.id == message.id);
          if (i >= 0) {
            queued[i] = message.copyWith(state: ChatMessageState.failed);
          }
        },
      );
    }
    return const Ok(null);
  }

  Future<Result<ChatMessage>> retry(ChatMessage message) {
    queued.removeWhere((m) => m.id == message.id);
    return send(
      bookingId: message.bookingId,
      text: message.text ?? '',
      mediaPath: message.mediaPath,
      idempotencyKey: message.id,
    );
  }

  Future<Result<ChatMessage>> _sendRemote({
    required String bookingId,
    required String text,
    required String key,
    String? mediaPath,
  }) async {
    final result = await _remote.send(
      bookingId: bookingId,
      text: text,
      mediaPath: mediaPath,
      idempotencyKey: key,
    );
    return result.when(
      onOk: Ok.new,
      onErr: (failure) {
        final failed = ChatMessage(
          id: key,
          bookingId: bookingId,
          senderId: 'local',
          senderRole: 'customer',
          text: text,
          mediaPath: mediaPath,
          createdAt: DateTime.now().toUtc(),
          state: ChatMessageState.failed,
        );
        queued.removeWhere((m) => m.id == key);
        queued.add(failed);
        return Err(failure);
      },
    );
  }
}
