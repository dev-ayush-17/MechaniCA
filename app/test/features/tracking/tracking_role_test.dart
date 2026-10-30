import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mechupp_app/composition/providers.dart';

void main() {
  test('default_tracking_role_is_customer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(trackingRoleProvider), 'customer');
  });

  test('mechanic_flavor_overrides_tracking_role', () {
    final container = ProviderContainer(
      overrides: [trackingRoleProvider.overrideWithValue('mechanic')],
    );
    addTearDown(container.dispose);
    expect(container.read(trackingRoleProvider), 'mechanic');
  });
}
