import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/vehicles/domain/indian_plate.dart';

void main() {
  test('rejects_mock_plate_br80y024', () {
    expect(isValidIndianPlate('BR80Y 024'), isFalse);
    expect(isValidIndianPlate('br80y024'), isFalse);
  });

  test('accepts_br01ab1234', () {
    expect(isValidIndianPlate('BR01AB1234'), isTrue);
    expect(isValidIndianPlate('br01 ab 1234'), isTrue);
    expect(normalizeIndianPlate('br01 ab 1234'), 'BR01AB1234');
  });
}
