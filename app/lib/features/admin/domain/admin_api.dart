import '../../../core/error/result.dart';
import 'admin_models.dart';

abstract class AdminApi {
  Future<Result<List<AdminUserRow>>> searchUsers(String query);
  Future<Result<AdminUserRow>> suspendUser(String userId, {required String reason});
  Future<Result<List<AdminApplicationRow>>> listApplications();
  Future<Result<void>> decideVerification(String mechanicId, {required bool approve, String? reason});
  Future<Result<List<AdminBookingRow>>> listBookings({String? status, String? city});
  Future<Result<AdminRevenue>> revenue(String window);
  Future<Result<List<AdminCouponRow>>> listCoupons();
  Future<Result<AdminCouponRow>> createCoupon({required String code, required String title});
  Future<Result<AdminCouponRow>> disableCoupon(String code);
  Future<Result<List<AdminDisputeRow>>> listDisputes();
  Future<Result<void>> addDisputeNote(String id, {required String note});
  Future<Result<void>> resolveDispute(String id, {required String resolution, required int amountPaise, required String note});
  Future<Result<List<AdminAuditRow>>> listAudit();
  Future<Result<Map<String, int>>> analyticsCounts();
}
