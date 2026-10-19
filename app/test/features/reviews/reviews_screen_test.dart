import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/reviews/data/fake_review_repository.dart';
import 'package:mechupp_app/features/reviews/presentation/mechanic_reviews_screen.dart';
import 'package:mechupp_app/features/reviews/presentation/submit_review_screen.dart';

void main() {
  testWidgets('submit and display a five star review', (tester) async {
    final reviews = FakeReviewRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reviewRepositoryProvider.overrideWithValue(reviews)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SubmitReviewScreen(bookingId: 'b1'),
        ),
      ),
    );

    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();
    expect(find.text('Thanks for the review.'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reviewRepositoryProvider.overrideWithValue(reviews)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MechanicReviewsScreen(mechanicId: 'mech_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('1 reviews'), findsOneWidget);
  });
}
