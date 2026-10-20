import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/flags/feature_flags.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/job_chat/data/fake_chat_service.dart';
import 'package:mechupp_app/features/job_chat/data/fake_telephony.dart';
import 'package:mechupp_app/features/job_chat/data/offline_chat_service.dart';
import 'package:mechupp_app/features/job_chat/domain/telephony_port.dart';
import 'package:mechupp_app/features/job_chat/presentation/job_chat_screen.dart';

void main() {
  testWidgets('call_hidden_when_flag_off', (tester) async {
    final chat = OfflineChatService(
      remote: FakeChatService(),
      isOnline: () => true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatServiceProvider.overrideWithValue(chat),
          featureFlagsProvider.overrideWithValue(const StaticFeatureFlags()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const JobChatScreen(bookingId: 'book_1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Call'), findsNothing);
  });

  test('adapter_does_not_return_the_user_phone', () async {
    const customer = '+919876543210';
    const mechanic = '+919811122233';
    final result = await FakeTelephony().mask(
      bookingId: 'book_1',
      partyA: customer,
      partyB: mechanic,
    );
    final call = (result as Ok<MaskedCall>).value;
    expect(call.dialNumber, kMaskedDialNumber);
    expect(call.dialNumber, isNot(customer));
    expect(call.dialNumber, isNot(mechanic));
    expect(call.dialNumber.contains('9876543210'), isFalse);
    expect(call.dialNumber.contains('9811122233'), isFalse);
  });
}
