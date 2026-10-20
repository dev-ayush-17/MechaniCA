import 'dart:math' as math;

import 'location_point.dart';

const staleAfter = Duration(seconds: 60);
const jumpMaxKm = 2.0;
const jumpWindow = Duration(seconds: 5);
const geofenceM = 150.0;
const dutyFast = Duration(seconds: 5);
const dutySlow = Duration(seconds: 15);
const arrivedPublishFor = Duration(minutes: 2);
const speedFastKmh = 5.0;
const accuracyTargetM = 50.0;
const troubleAfter = Duration(minutes: 5);

const locationOpenStatuses = {'mechanicAssigned', 'enRoute', 'arrived'};
const inServiceOrLater = {
  'inService',
  'completed',
  'paid',
  'cancelled',
  'failed',
  'disputed',
};

bool isStale(LocationPoint point, DateTime now, {Duration threshold = staleAfter}) {
  return now.difference(point.recordedAt) > threshold;
}

String lastSeenLabel(LocationPoint point, DateTime now) {
  final minutes = math.max(1, now.difference(point.recordedAt).inMinutes);
  return 'Last seen $minutes min ago.';
}

/// Drop GPS drift: more than 2 km in 5 seconds is not shown or stored.
LocationPoint? acceptPoint(LocationPoint? previous, LocationPoint candidate) {
  if (previous == null) return candidate;
  final elapsed = candidate.recordedAt.difference(previous.recordedAt);
  if (elapsed <= Duration.zero) return null;
  final distanceKm = haversineKm(
    previous.lat,
    previous.lng,
    candidate.lat,
    candidate.lng,
  );
  if (distanceKm > jumpMaxKm && elapsed <= jumpWindow) return null;
  return candidate;
}

bool withinGeofence(
  LocationPoint mechanic,
  double destLat,
  double destLng, {
  double radiusM = geofenceM,
}) {
  return haversineKm(mechanic.lat, mechanic.lng, destLat, destLng) * 1000 <= radiusM;
}

Duration? dutyInterval(String status, double? speedMps) {
  if (!locationOpenStatuses.contains(status)) return null;
  final speedKmh = (speedMps ?? 0) * 3.6;
  if (status == 'enRoute' && speedKmh > speedFastKmh) return dutyFast;
  return dutySlow;
}

bool stillPublishingAfterArrived(DateTime arrivedAt, DateTime now) {
  return now.difference(arrivedAt) < arrivedPublishFor;
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const radiusKm = 6371.0;
  final phi1 = _rad(lat1);
  final phi2 = _rad(lat2);
  final dPhi = _rad(lat2 - lat1);
  final dLambda = _rad(lng2 - lng1);
  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
  return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
