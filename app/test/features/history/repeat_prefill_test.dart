import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/features/booking/domain/booking.dart';
import 'package:mechupp_app/features/booking/domain/repeat_prefill.dart';
import 'package:mechupp_app/features/catalog/data/fake_catalog_repository.dart';
import 'package:mechupp_app/features/catalog/data/fake_quote_api.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  test('repeat_recalculates_price', () async {
    const oldTotalPaise = 999999;
    const booking = Booking(
      id: 'bk_old',
      displayNumber: 'MCOLD',
      status: BookingStatus.paid,
      serviceCode: 'general_service',
      mode: 'instant',
      urgency: 'normal',
      totalPaise: oldTotalPaise,
      cancelFeePaise: 0,
      version: 1,
      vehicleId: 'veh_seed_1',
      addressId: 'addr_home',
    );
    final prefill = RepeatPrefill.fromBooking(booking);
    expect(prefill.vehicleId, booking.vehicleId);
    expect(prefill.serviceCode, booking.serviceCode);
    expect(prefill.addressId, booking.addressId);

    final result = await FakeQuoteApi(catalog: FakeCatalogRepository()).quote(
      serviceCode: prefill.serviceCode,
      vehicleId: prefill.vehicleId,
      vehicleType: VehicleType.twoWheeler,
    );
    final quoted = switch (result) {
      Ok(:final value) => value.totalPaise,
      Err() => oldTotalPaise,
    };
    expect(quoted, isNot(oldTotalPaise));
  });
}
