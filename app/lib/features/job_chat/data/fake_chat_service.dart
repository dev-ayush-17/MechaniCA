import '../../../core/error/result.dart';
import '../domain/chat_message.dart';
import '../domain/chat_service.dart';

class FakeChatService implements ChatService {
  FakeChatService({this.failNext = false});

  bool failNext;
  final List<ChatMessage> messages = [];

  @override
  Future<Result<ChatMessage>> send({
    required String bookingId,
    required String text,
    String? mediaPath,
    String? idempotencyKey,
  }) async {
    if (failNext) {
      failNext = false;
      return const Err(Unavailable('Could not send. Try again.'));
    }
    final existing = messages.cast<ChatMessage?>().firstWhere(
          (m) => m?.id == idempotencyKey,
          orElse: () => null,
        );
    if (existing != null) return Ok(existing);
    final message = ChatMessage(
      id: idempotencyKey ?? 'msg_${messages.length + 1}',
      bookingId: bookingId,
      senderId: 'demo-user',
      senderRole: 'customer',
      text: text,
      mediaPath: mediaPath,
      createdAt: DateTime.now().toUtc(),
      state: ChatMessageState.sent,
    );
    messages.add(message);
    return Ok(message);
  }

  @override
  Future<Result<List<ChatMessage>>> list(String bookingId, {DateTime? after}) async {
    final items = messages.where((m) => m.bookingId == bookingId).toList();
    if (after == null) return Ok(items);
    return Ok(items.where((m) => m.createdAt.isAfter(after)).toList());
  }
}
