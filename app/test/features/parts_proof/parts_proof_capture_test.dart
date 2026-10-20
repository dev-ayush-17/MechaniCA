import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/parts_proof/domain/parts_proof.dart';
import 'package:mechupp_app/features/parts_proof/presentation/parts_proof_capture_screen.dart';

void main() {
  testWidgets('three photo labels render on capture', (tester) async {
    final queue = ProofUploadQueue();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: PartsProofCaptureScreen(
            bookingId: 'b1',
            lineId: 'l1',
            queue: queue,
            pickImage: (kind) async => 'local/${kind.apiValue}.jpg',
          ),
        ),
      ),
    );

    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(find.text('Old part'), findsOneWidget);
    expect(find.text('Complete (photos required)'), findsOneWidget);

    await tester.tap(find.text('Before'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('After'));
    await tester.pumpAndSettle();
    expect(find.text('Complete (photos required)'), findsOneWidget);

    await tester.tap(find.text('Old part'));
    await tester.pumpAndSettle();
    expect(find.text('Complete'), findsOneWidget);
  });
}
