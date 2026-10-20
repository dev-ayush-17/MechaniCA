import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/auth/presentation/permission_screens.dart';
import 'package:mechupp_app/features/notifications/data/fake_notification_inbox.dart';
import 'package:mechupp_app/features/notifications/data/fake_push_permission.dart';
import 'package:mechupp_app/features/notifications/domain/inbox_notification.dart';
import 'package:mechupp_app/features/notifications/domain/notification_inbox.dart';
import 'package:mechupp_app/features/notifications/presentation/notifications_screen.dart';
import 'package:mechupp_app/features/notifications/presentation/push_denied_banner.dart';
import 'package:mechupp_app/navigation/route_names.dart';

class _EmptyInbox implements NotificationInbox {
  @override
  Future<Result<List<InboxNotification>>> list() async => const Ok([]);

  @override
  Future<Result<InboxNotification>> markRead(String id) async =>
      const Err(NotFound('We could not find that notification.'));

  @override
  Future<Result<void>> delete(String id) async => const Ok(null);

  @override
  Future<Result<void>> markAllRead(List<String> ids) async => const Ok(null);
}

void main() {
  testWidgets('empty notifications copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWithValue(_EmptyInbox()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(kNotificationsEmptyCopy), findsOneWidget);
  });

  testWidgets('denied banner copy on home when flag is set', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushPermissionDeniedProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomePushDeniedBanner()),
        ),
      ),
    );
    expect(find.text(kPushDeniedBannerCopy), findsOneWidget);
  });

  testWidgets('permission screen prompts the OS once', (tester) async {
    final permission = FakePushPermission();
    final router = GoRouter(
      initialLocation: RouteNames.notificationPermission,
      routes: [
        GoRoute(
          path: RouteNames.notificationPermission,
          builder: (_, __) => const NotificationPermissionScreen(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => const SizedBox(key: Key('home')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushPermissionProvider.overrideWithValue(permission),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Allow Notifications'));
    await tester.pump();
    await tester.pump();
    expect(permission.requestCount, 1);
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  test('mark-all-read sends batches of 50', () async {
    final seed = List<InboxNotification>.generate(
      51,
      (i) => InboxNotification(
        id: 'n$i',
        title: 'T',
        body: 'B',
        templateId: 'bookingConfirmed',
        deepLink: '/booking/details?id=b1',
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
    final inbox = FakeNotificationInbox(seed);
    await inbox.markAllRead(seed.map((item) => item.id).toList());
    expect(inbox.items.every((item) => item.isRead), isTrue);
  });
}
