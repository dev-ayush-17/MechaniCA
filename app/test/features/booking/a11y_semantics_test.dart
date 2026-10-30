import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/domain/pricing.dart';
import 'package:mechupp_app/features/booking/presentation/price_step.dart';
import 'package:mechupp_app/features/emergency/emergency_screen.dart';
import 'package:mechupp_app/l10n/app_localizations.dart';
import 'package:mechupp_app/widgets/shared/app_widgets.dart';

const _quote = PriceQuote(
  laborPaise: 59900,
  partsPaise: 0,
  feePaise: 4900,
  discountPaise: 0,
  cgstPaise: 5832,
  sgstPaise: 5832,
  totalPaise: 76464,
);

Widget _localized({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: Scaffold(body: home),
    ),
  );
}

void main() {
  testWidgets('semantics_on_the_pay_button', (tester) async {
    await tester.pumpWidget(
      _localized(home: PriceStep(onConfirm: () async => null, quote: _quote)),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Confirm ₹764.64'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).label, 'Confirm ₹764.64');
  });

  testWidgets('semantics_on_the_sos_control', (tester) async {
    await tester.pumpWidget(_localized(home: const EmergencyScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.bySemanticsLabel('SOS'), findsOneWidget);
    final sos = tester.getSemantics(find.byKey(const ValueKey('sos-control')));
    expect(sos.flagsCollection.isButton, isTrue);
  });

  testWidgets('hi_locale_loads_the_booking_confirm_button', (tester) async {
    await tester.pumpWidget(
      _localized(
        locale: const Locale('hi'),
        home: PriceStep(onConfirm: () async => null, quote: _quote),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('₹764.64 की पुष्टि करें'), findsOneWidget);
    expect(find.bySemanticsLabel('₹764.64 की पुष्टि करें'), findsOneWidget);
  });

  testWidgets('price_total_readable_at_1_6_text_scale', (tester) async {
    await tester.pumpWidget(
      _localized(
        textScale: 1.6,
        home: PriceStep(onConfirm: () async => null, quote: _quote),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('₹764.64'), findsWidgets);
    expect(find.text('Total Amount'), findsOneWidget);
  });
}
