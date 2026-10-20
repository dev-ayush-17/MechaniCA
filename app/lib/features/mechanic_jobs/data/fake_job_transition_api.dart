import '../../../core/error/result.dart';
import '../domain/job_transition_api.dart';

class FakeJobTransitionApi implements JobTransitionApi {
  String lastTo = '';

  @override
  Future<Result<String>> transition(String bookingId, String to) async {
    lastTo = to;
    return Ok(to);
  }
}
