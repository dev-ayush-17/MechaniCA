class LocationPoint {
  const LocationPoint({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.recordedAt,
    this.speedMps,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final DateTime recordedAt;
  final double? speedMps;
}

class LocationSnapshot {
  const LocationSnapshot({this.mechanic, this.customer});

  final LocationPoint? mechanic;
  final LocationPoint? customer;
}
