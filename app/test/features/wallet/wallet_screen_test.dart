import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/wallet/data/fake_wallet_api.dart';
import 'package:mechupp_app/features/wallet/wallet_screen.dart';

void main() {
  testWidgets('empty_wallet_shows_no_transactions_yet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletApiProvider.overrideWithValue(FakeWalletApi()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WalletScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No transactions yet.'), findsOneWidget);
  });
}
