import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/auth/presentation/permission_screens.dart';
import 'package:mechupp_app/navigation/app_router.dart';

Iterable<String> _paths(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route.path;
    yield* _paths(route.routes);
  }
}

void main() {
  test('forgot_password_route_is_gone', () {
    final paths = _paths(appRouter.configuration.routes).toList();

    expect(paths, isNot(contains('/forgot-password')));
    expect(paths, containsAll(['/login', '/otp', '/location-permission']));
  });

  testWidgets('permission_screens_keep_their_copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.darkTheme, home: const LocationPermissionScreen()),
    );
    expect(find.text('Enable Location'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
          theme: AppTheme.darkTheme,
          home: const NotificationPermissionScreen()),
    );
    expect(find.text('Stay Updated'), findsOneWidget);
  });
}
