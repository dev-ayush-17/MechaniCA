class DeviceFix {
  const DeviceFix({this.lat, this.lng, this.denied = false, this.message});

  final double? lat;
  final double? lng;
  final bool denied;
  final String? message;

  bool get hasPoint => lat != null && lng != null;
}

/// Reads the device location. Widgets never import the platform plugin.
abstract interface class DeviceLocation {
  Future<DeviceFix> current();
}
