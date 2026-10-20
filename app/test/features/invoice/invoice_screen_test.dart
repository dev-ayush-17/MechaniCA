import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/invoice/data/fake_invoice_api.dart';
import 'package:mechupp_app/features/invoice/domain/invoice.dart';
import 'package:mechupp_app/features/invoice/invoice_screen.dart';

Invoice _paid() => Invoice(
      bookingId: 'b-paid',
      number: 'MC-202606-000042',
      version: 1,
      totalPaise: 105964,
      cgstPaise: 8082,
      sgstPaise: 8082,
      gstin: '22AAAAA0000A1Z5',
      customerName: 'Priya Sharma',
      vehicleRegistration: 'BR01AB1234',
      mechanicDisplayName: 'Imran',
      paymentMethod: 'upi',
      downloadUrl: 'https://storage.fake/download/invoices/b-paid/v1.pdf',
      createdAt: DateTime.utc(2026, 6, 1, 10),
      lines: const [
        InvoiceLine(name: 'General Service', quantity: 1, amountPaise: 59900),
      ],
    );

Widget _app(FakeInvoiceApi api, String bookingId) {
  return ProviderScope(
    overrides: [
      invoiceApiProvider.overrideWithValue(api),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: InvoiceScreen(bookingId: bookingId),
    ),
  );
}

void main() {
  testWidgets('missing invoice shows loading then error not another invoice',
      (tester) async {
    await tester.pumpWidget(_app(FakeInvoiceApi(), 'b-missing'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    expect(find.text('We could not find that invoice.'), findsOneWidget);
    expect(find.text('₹664'), findsNothing);
    expect(find.textContaining('INV'), findsNothing);
  });

  testWidgets('screen uses the booking id from the route', (tester) async {
    await tester.pumpWidget(
      _app(FakeInvoiceApi(invoices: {'b-paid': _paid()}), 'b-paid'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('MC-202606-000042'), findsOneWidget);
    expect(find.text('₹1059'), findsWidgets);
    expect(find.text('₹664'), findsNothing);
  });

  testWidgets('share opens the share sheet with a pdf file', (tester) async {
    final shared = <String>[];
    final api = FakeInvoiceApi(invoices: {'b-paid': _paid()});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceApiProvider.overrideWithValue(api),
          saveInvoicePdfProvider.overrideWithValue((bookingId, bytes) async {
            final file = File('${Directory.systemTemp.path}/invoice-$bookingId.pdf');
            file.writeAsBytesSync(bytes, flush: true);
            return file.path;
          }),
          shareInvoicePdfProvider.overrideWithValue((path) async {
            shared.add(path);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const InvoiceScreen(bookingId: 'b-paid'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(shared, hasLength(1));
    expect(shared.first.endsWith('.pdf'), isTrue);
    expect(File(shared.first).existsSync(), isTrue);
  });
}
