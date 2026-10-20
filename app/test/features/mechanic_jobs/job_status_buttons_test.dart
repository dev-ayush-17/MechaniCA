import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/mechanic_jobs/presentation/job_status_buttons.dart';

void main() {
  testWidgets('legal status buttons show the next action', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: JobStatusButtons(
            status: 'mechanicAssigned',
            onAction: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Start trip'), findsOneWidget);
    await tester.tap(find.text('Start trip'));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: JobStatusButtons(
            status: 'inService',
            hasPartLines: false,
            onAction: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Complete'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: JobStatusButtons(
            status: 'inService',
            hasPartLines: true,
            onAction: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Complete'), findsOneWidget);
    await tester.tap(find.text('Complete'));
    await tester.pump();
    expect(taps, 1);
  });
}
