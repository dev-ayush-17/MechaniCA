import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/parts_proof/domain/parts_proof.dart';
import 'package:mechupp_app/features/parts_proof/presentation/customer_proofs_screen.dart';

void main() {
  testWidgets('three photo labels render', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CustomerProofsScreen(
            bookingId: 'b1',
            seed: [
              PartsProof(
                id: '1',
                bookingId: 'b1',
                lineId: 'l1',
                kind: ProofKind.before,
                path: 'partsProof/b1/l1/before/a.jpg',
              ),
              PartsProof(
                id: '2',
                bookingId: 'b1',
                lineId: 'l1',
                kind: ProofKind.after,
                path: 'partsProof/b1/l1/after/b.jpg',
              ),
              PartsProof(
                id: '3',
                bookingId: 'b1',
                lineId: 'l1',
                kind: ProofKind.oldPart,
                path: 'partsProof/b1/l1/old_part/c.jpg',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Before Service'), findsOneWidget);
    expect(find.text('After Service'), findsOneWidget);
    expect(find.text('Old part'), findsOneWidget);
  });
}
