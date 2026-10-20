import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/booking/domain/complete_gate.dart';

void main() {
  test('parts_complete_blocked_without_photos', () {
    expect(
      completeBlockedWithoutPhotos(
        hasPartReplacementLine: true,
        queuedOrStoredCount: 2,
      ),
      isTrue,
    );
    expect(
      completeBlockedWithoutPhotos(
        hasPartReplacementLine: true,
        queuedOrStoredCount: 3,
      ),
      isFalse,
    );
    expect(
      completeBlockedWithoutPhotos(
        hasPartReplacementLine: false,
        queuedOrStoredCount: 0,
      ),
      isFalse,
    );
  });
}
