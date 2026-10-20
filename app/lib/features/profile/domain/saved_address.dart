class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.pincode,
    required this.lat,
    required this.lng,
    required this.isDefault,
    this.landmark,
  });

  final String id;
  final String label;
  final String line1;
  final String city;
  final String pincode;
  final double lat;
  final double lng;
  final bool isDefault;
  final String? landmark;

  String get fullAddress {
    final mark = landmark == null || landmark!.isEmpty ? '' : '$landmark, ';
    return '$line1, $mark$city $pincode';
  }
}
