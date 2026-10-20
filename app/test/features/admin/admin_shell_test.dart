import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/admin/presentation/admin_shell.dart';
import 'package:mechupp_app/navigation/admin_router.dart';

void main() {
  testWidgets('900 px window shows large-screen message', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: adminRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(largeScreenMessage), findsOneWidget);
  });

  testWidgets('wide window shows admin queues', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: adminRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(largeScreenMessage), findsNothing);
    expect(find.text('Users'), findsWidgets);
  });
}
