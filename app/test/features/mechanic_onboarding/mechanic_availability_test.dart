import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/mechanic_onboarding/data/fake_mechanic_repository.dart';
import 'package:mechupp_app/features/mechanic_onboarding/presentation/mechanic_controller.dart';
import 'package:mechupp_app/features/mechanic_onboarding/domain/mechanic_repository.dart';
import 'package:mechupp_app/features/mechanic_onboarding/presentation/mechanic_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoadedMechanicNotifier extends MechanicNotifier {
  _LoadedMechanicNotifier(FakeMechanicRepository repo)
      : super(repo, () async => 'token') {
    state = const MechanicState(
      profile: MechanicProfile(
        id: 'm1',
        displayName: 'Test',
        photoPath: 'p',
        yearsExperience: 1,
        languages: ['en'],
        serviceArea: null,
        verified: false,
        verificationStatus: VerificationStatus.pending,
        online: false,
      ),
    );
  }

  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('unverified_mechanic_cannot_go_online', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeMechanicRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mechanicProvider.overrideWith(
            (ref) => _LoadedMechanicNotifier(repo),
          ),
        ],
        child: const MaterialApp(home: MechanicHomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final toggle = find.byType(SwitchListTile);
    expect(toggle, findsOneWidget);
    final switchWidget = tester.widget<SwitchListTile>(toggle);
    expect(switchWidget.onChanged, isNull);
  });
}
