/// Indian vehicle registration validation (FR-VEH-002).
library;

final _platePattern = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,3}[0-9]{1,4}$');

/// Normalizes user input: trim, remove spaces, uppercase.
String normalizeIndianPlate(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// The demo mock plate must stay invalid (FR-VEH-002).
bool isRejectedMockPlate(String normalized) => normalized == 'BR80Y024';

bool isValidIndianPlate(String raw) {
  final normalized = normalizeIndianPlate(raw);
  if (normalized.isEmpty) return false;
  if (isRejectedMockPlate(normalized)) return false;
  return _platePattern.hasMatch(normalized);
}

/// User-facing message when validation fails.
const invalidPlateMessage = 'Enter a valid registration number.';
