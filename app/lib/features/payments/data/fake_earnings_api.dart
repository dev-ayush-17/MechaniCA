import '../../../core/error/result.dart';
import '../domain/earnings.dart';
import '../domain/earnings_api.dart';

class FakeEarningsApi implements EarningsApi {
  FakeEarningsApi({
    this.items = const [],
    this.notice = 'Recorded earnings. Bank payout is not live yet.',
  });

  final List<MechanicEarning> items;
  final String notice;

  @override
  Future<Result<EarningsList>> list() async {
    return Ok(EarningsList(items: items, notice: notice));
  }
}
