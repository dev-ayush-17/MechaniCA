import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/features/booking/domain/pricing.dart';
import 'package:mechupp_app/features/catalog/domain/service_definition.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle.dart';

const _general = ServiceDefinition(
  code: 'general_service',
  name: 'General Service',
  description: 'Full service',
  baseLaborPaise: 59900,
  durationMin: 60,
  active: true,
  sortOrder: 1,
);

void main() {
  const pricing = PricingService();

  test('gst_on_59900_plus_4900_splits', () {
    final result = pricing.quote(
      const QuoteInput(
        service: _general,
        vehicleType: VehicleType.twoWheeler,
      ),
    );
    final quote = (result as Ok<PriceQuote>).value;
    expect(quote.laborPaise, 59900);
    expect(quote.feePaise, 4900);
    expect(quote.cgstPaise, 5832);
    expect(quote.sgstPaise, 5832);
    expect(quote.gstPaise, 11664);
    expect(quote.totalPaise, 76464);
    expect(formatPaise(quote.laborPaise), '₹599');
  });

  test('four_wheeler_labor_is_one_and_a_half', () {
    final result = pricing.quote(
      const QuoteInput(
        service: _general,
        vehicleType: VehicleType.fourWheeler,
      ),
    );
    final quote = (result as Ok<PriceQuote>).value;
    expect(quote.laborPaise, 89850);
    const taxable = 89850 + 4900;
    const gst = taxable * 18 ~/ 100;
    expect(quote.gstPaise, gst);
    expect((quote.cgstPaise - quote.sgstPaise).abs(), lessThanOrEqualTo(1));
    expect(quote.totalPaise, taxable + gst);
  });
}
