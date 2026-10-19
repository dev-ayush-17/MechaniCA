import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/presentation/extra_work_card.dart';

void main() {
  testWidgets('extra_line_reject', (tester) async {
    var rejected = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ExtraWorkCard(
            name: 'Brake pads',
            amountPaise: 12000,
            onApprove: () {},
            onReject: () => rejected = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(rejected, isTrue);
  });
}
