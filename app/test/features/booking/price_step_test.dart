import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/domain/pricing.dart';
import 'package:mechupp_app/features/booking/presentation/price_step.dart';

void main() {
  testWidgets('price_step_shows_labor_fee_gst_total', (tester) async {
    const quote = PriceQuote(
      laborPaise: 59900,
      partsPaise: 0,
      feePaise: 4900,
      discountPaise: 0,
      cgstPaise: 5832,
      sgstPaise: 5832,
      totalPaise: 76464,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PriceStep(onConfirm: () async {}, quote: quote),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('₹599'), findsOneWidget);
    expect(find.text('Labor'), findsOneWidget);
    expect(find.text('Convenience fee'), findsOneWidget);
    expect(find.text('GST'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('₹49'), findsOneWidget);
    expect(find.text('₹116.64'), findsOneWidget);
    expect(find.text('₹764.64'), findsWidgets);
  });
}
