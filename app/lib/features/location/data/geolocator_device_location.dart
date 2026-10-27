import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/device_location.dart';

class GeolocatorDeviceLocation implements DeviceLocation {
  static const _timeout = Duration(seconds: 8);

  @override
  Future<DeviceFix> current() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return const DeviceFix(
        denied: true,
        message: 'Turn on location services, then try again.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DeviceFix(
        denied: true,
        message: 'Location permission was denied.',
      );
    }
    final last = await Geolocator.getLastKnownPosition();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _timeout,
        ),
      );
      return DeviceFix(lat: position.latitude, lng: position.longitude);
    } on TimeoutException {
      if (last != null) {
        return DeviceFix(lat: last.latitude, lng: last.longitude);
      }
      return const DeviceFix(
        denied: true,
        message: 'Could not get a location fix. Try again.',
      );
    }
  }
}
