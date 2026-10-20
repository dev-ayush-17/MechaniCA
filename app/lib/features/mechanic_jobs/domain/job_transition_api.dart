import '../../../core/error/result.dart';

abstract class JobTransitionApi {
  Future<Result<String>> transition(String bookingId, String to);
}
