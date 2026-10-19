import '../../../core/error/result.dart';
import 'earnings.dart';

/// Paid-share list for the signed-in mechanic (FR-MEC-007).
abstract class EarningsApi {
  Future<Result<EarningsList>> list();
}
