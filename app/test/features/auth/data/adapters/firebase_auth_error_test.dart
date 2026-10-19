import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica_app/core/error/result.dart';
import 'package:mechanica_app/features/auth/data/adapters/firebase_auth_service.dart';

void main() {
  test('wrong_code_maps_to_invalid_input', () {
    final failure = mapFirebaseAuthError(
      FirebaseAuthException(code: 'invalid-verification-code'),
    );
    expect(failure, isA<InvalidInput>());
    expect(failure.message, 'That code is incorrect.');
  });

  test('too_many_requests_maps_to_rate_limited', () {
    expect(
      mapFirebaseAuthError(FirebaseAuthException(code: 'too-many-requests')),
      isA<RateLimited>(),
    );
  });

  test('unknown_codes_do_not_leak_sdk_text', () {
    final failure = mapFirebaseAuthError(
      FirebaseAuthException(code: 'weird', message: 'internal detail 123456'),
    );
    expect(failure, isA<Unavailable>());
    expect(failure.message, isNot(contains('123456')));
  });
}
