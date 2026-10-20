import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/config/app_config.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/auth/data/fake_account_api.dart';
import 'package:mechupp_app/features/auth/data/fake_auth_service.dart';
import 'package:mechupp_app/features/auth/domain/account_api.dart';
import 'package:mechupp_app/features/auth/domain/auth_service.dart';
import 'package:mechupp_app/features/profile/profile_screen.dart';
import 'package:mechupp_app/widgets/shared/app_widgets.dart';

void main() {
  testWidgets('profile save name', (tester) async {
    final accounts = FakeAccountApi();
    final session = Session(
      userId: 'u_profile',
      idToken: 'tok',
      expiresAt: DateTime.utc(2027),
      role: 'customer',
    );
    await accounts.bootstrap(session, intent: AccountIntent.customer, name: 'Old Name');
    final account = (await accounts.me(session)).when(
      onOk: (value) => value,
      onErr: (_) => throw StateError('missing account'),
    );
    final auth = AuthNotifier(
      FakeAuthService(env: AppEnv.dev, clock: const SystemClock()),
      accounts,
    )..hydrate(session, account);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountApiProvider.overrideWithValue(accounts),
          authProvider.overrideWith((ref) => auth),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const EditProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Asha Kumar');
    await tester.tap(find.widgetWithText(AppButton, 'Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Profile updated successfully!'), findsOneWidget);
    expect(auth.state.account?.name, 'Asha Kumar');
  });
}
