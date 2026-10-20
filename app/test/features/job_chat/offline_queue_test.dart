import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/features/job_chat/data/fake_chat_service.dart';
import 'package:mechupp_app/features/job_chat/data/offline_chat_service.dart';
import 'package:mechupp_app/features/job_chat/domain/chat_message.dart';

void main() {
  test('offline_text_queues', () async {
    final remote = FakeChatService();
    var online = false;
    final chat = OfflineChatService(remote: remote, isOnline: () => online);

    final queued = await chat.send(bookingId: 'book_1', text: 'Stuck on NH31');
    expect(queued, isA<Ok<ChatMessage>>());
    final pending = (queued as Ok<ChatMessage>).value;
    expect(pending.state, ChatMessageState.sending);
    expect(chat.queued, hasLength(1));
    expect(remote.messages, isEmpty);

    online = true;
    final flushed = await chat.flush();
    expect(flushed, isA<Ok<void>>());
    expect(chat.queued, isEmpty);
    expect(remote.messages, hasLength(1));
    expect(remote.messages.single.text, 'Stuck on NH31');
    expect(remote.messages.single.state, ChatMessageState.sent);
  });
}
