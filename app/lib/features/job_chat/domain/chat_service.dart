import '../../../core/error/result.dart';
import 'chat_message.dart';

abstract interface class ChatService {
  Future<Result<ChatMessage>> send({
    required String bookingId,
    required String text,
    String? mediaPath,
    String? idempotencyKey,
  });

  Future<Result<List<ChatMessage>>> list(String bookingId, {DateTime? after});
}
