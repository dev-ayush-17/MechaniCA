import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica_app/main.dart';

void main() {
  testWidgets('splash_shows_brand', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MechaniCAApp()));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('MechaniCA'), findsOneWidget);

    // Let the splash timers and navigation finish so none stay pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Skip'), findsOneWidget); // onboarding follows splash
  });
}
