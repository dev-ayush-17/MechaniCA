/// Allowed sync queue kinds for M03 (docs/prd/09-domain-and-data-model.md).
class SyncQueueKinds {
  SyncQueueKinds._();

  static const vehicleUpsert = 'vehicle_upsert';
  static const vehicleDelete = 'vehicle_delete';

  static const allowedForM03 = {vehicleUpsert, vehicleDelete};

  static void assertVehicleKind(String kind) {
    if (!allowedForM03.contains(kind)) {
      throw ArgumentError('Unsupported sync kind: $kind');
    }
  }

  static bool isBookingCreate(String kind) => kind == 'booking_create';
}
