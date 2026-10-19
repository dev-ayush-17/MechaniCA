import '../../../core/error/result.dart';
import '../../catalog/domain/service_definition.dart';
import '../../vehicles/domain/vehicle.dart';

/// 15000 bps = 1.5x. Integers only so labor never uses a binary float.
const int kFourWheelerLaborBps = 15000;
const int kGstBps = 1800;
const int kConvenienceFeePaise = 4900;
const int kBpsDenominator = 10000;

class PricingConfig {
  const PricingConfig({
    this.convenienceFeePaise = kConvenienceFeePaise,
    this.fourWheelerLaborBps = kFourWheelerLaborBps,
    this.gstBps = kGstBps,
  });

  final int convenienceFeePaise;
  final int fourWheelerLaborBps;
  final int gstBps;
}

class QuoteInput {
  const QuoteInput({
    required this.service,
    required this.vehicleType,
    this.partsPaise = 0,
    this.discountPaise = 0,
  });

  final ServiceDefinition service;
  final VehicleType vehicleType;
  final int partsPaise;
  final int discountPaise;
}

class PriceQuote {
  const PriceQuote({
    required this.laborPaise,
    required this.partsPaise,
    required this.feePaise,
    required this.discountPaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.totalPaise,
  });

  final int laborPaise;
  final int partsPaise;
  final int feePaise;
  final int discountPaise;
  final int cgstPaise;
  final int sgstPaise;
  final int totalPaise;

  int get gstPaise => cgstPaise + sgstPaise;
}

/// Pure estimate. The use case loads catalog, coupon, and vehicle first.
class PricingService {
  const PricingService([this.config = const PricingConfig()]);

  final PricingConfig config;

  Result<PriceQuote> quote(QuoteInput input) {
    if (!input.service.active) {
      return const Err(InvalidInput('This service is not available.'));
    }
    if (input.partsPaise < 0 || input.discountPaise < 0) {
      return const Err(InvalidInput('Amounts cannot be negative.'));
    }
    if (input.service.baseLaborPaise < 0) {
      return const Err(InvalidInput('Labor cannot be negative.'));
    }

    var labor = input.service.baseLaborPaise;
    if (input.vehicleType == VehicleType.fourWheeler) {
      labor = labor * config.fourWheelerLaborBps ~/ kBpsDenominator;
    }

    final discount =
        input.discountPaise > labor ? labor : input.discountPaise;
    final fee = config.convenienceFeePaise;
    final parts = input.partsPaise;
    final taxable = labor + fee + parts;
    final gstTotal = taxable * config.gstBps ~/ kBpsDenominator;
    final cgst = gstTotal ~/ 2;
    final sgst = gstTotal - cgst;
    return Ok(
      PriceQuote(
        laborPaise: labor,
        partsPaise: parts,
        feePaise: fee,
        discountPaise: discount,
        cgstPaise: cgst,
        sgstPaise: sgst,
        totalPaise: taxable - discount + gstTotal,
      ),
    );
  }
}

/// Rupee label from integer paise. Whole rupees omit the decimal.
String formatPaise(int paise) {
  final sign = paise < 0 ? '-' : '';
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final leftover = abs % 100;
  if (leftover == 0) {
    return '$sign₹$rupees';
  }
  return '$sign₹$rupees.${leftover.toString().padLeft(2, '0')}';
}
