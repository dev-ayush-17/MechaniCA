import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/job_chat/data/fake_chat_service.dart';
import 'package:mechupp_app/features/job_chat/data/offline_chat_service.dart';
import 'package:mechupp_app/features/job_chat/domain/chat_message.dart';
import 'package:mechupp_app/features/job_chat/presentation/job_chat_screen.dart';

void main() {
  testWidgets('empty thread copy', (tester) async {
    final chat = OfflineChatService(
      remote: FakeChatService(),
      isOnline: () => true,
    );
    await tester.pumpWidget(_host(chat));
    await tester.pump();
    await tester.pump();
    expect(find.text(kEmptyThreadCopy), findsOneWidget);
  });

  testWidgets('failed message retry', (tester) async {
    final remote = FakeChatService(failNext: true);
    final chat = OfflineChatService(remote: remote, isOnline: () => true);
    await tester.pumpWidget(_host(chat));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Are you close?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.text('Are you close?'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(remote.messages, isEmpty);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Retry'), findsNothing);
    expect(remote.messages, hasLength(1));
    expect(remote.messages.single.state, ChatMessageState.sent);
  });
}

Widget _host(OfflineChatService chat) {
  return ProviderScope(
    overrides: [chatServiceProvider.overrideWithValue(chat)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const JobChatScreen(bookingId: 'book_1'),
    ),
  );
}
