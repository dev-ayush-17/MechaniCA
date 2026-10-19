import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/presentation/coupon_apply_field.dart';
import 'package:mechupp_app/features/catalog/data/fake_catalog_repository.dart';
import 'package:mechupp_app/features/catalog/data/fake_quote_api.dart';
import 'package:mechupp_app/models/service_model.dart';

void main() {
  testWidgets('invalid_coupon_shows_server_message', (tester) async {
    final container = ProviderContainer(
      overrides: [
        quoteApiProvider.overrideWithValue(
          FakeQuoteApi(catalog: FakeCatalogRepository()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(bookingFlowProvider.notifier).selectService(
          const ServiceModel(
            id: 'general_service',
            name: 'General Service',
            description: 'Periodic inspection',
            price: 599,
            iconName: 'build',
            category: 'service',
            duration: '1h',
            isPopular: true,
            includes: [],
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: CouponApplyField()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Invalid coupon code'), findsOneWidget);
  });
}
