import '../../../core/error/result.dart';
import '../domain/admin_api.dart';
import '../domain/admin_models.dart';

class FakeAdminApi implements AdminApi {
  FakeAdminApi();

  final users = [
    const AdminUserRow(
      id: 'cust_1',
      name: 'Riya Sharma',
      phone: '+919876543210',
      role: 'customer',
      status: 'active',
    ),
  ];
  final applications = [
    const AdminApplicationRow(id: 'mech_1', displayName: 'Imran Khan', status: 'pending'),
  ];
  final bookings = [
    AdminBookingRow(
      id: 'b_disp',
      displayNumber: 'MCDISP01',
      status: 'arrived',
      city: 'Patna',
      createdAt: DateTime(2026, 6, 1),
      totalPaise: 76464,
    ),
  ];
  final coupons = [
    const AdminCouponRow(code: 'FLAT50', title: 'Flat ₹50 off', active: true, redemptionCount: 0),
  ];
  final disputes = [
    const AdminDisputeRow(
      id: 'd1',
      bookingId: 'b_disp',
      reason: 'Mechanic left early',
      status: 'open',
    ),
  ];
  final audit = <AdminAuditRow>[];

  @override
  Future<Result<List<AdminUserRow>>> searchUsers(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return Ok(users);
    return Ok(
      users.where((u) => u.name.toLowerCase().contains(needle) || u.phone.contains(needle)).toList(),
    );
  }

  @override
  Future<Result<AdminUserRow>> suspendUser(String userId, {required String reason}) async {
    final index = users.indexWhere((u) => u.id == userId);
    if (index < 0) return const Err(NotFound());
    final next = AdminUserRow(
      id: users[index].id,
      name: users[index].name,
      phone: users[index].phone,
      role: users[index].role,
      status: 'suspended',
    );
    users[index] = next;
    _audit('user_suspend', userId, reason);
    return Ok(next);
  }

  @override
  Future<Result<List<AdminApplicationRow>>> listApplications() async => Ok(applications);

  @override
  Future<Result<void>> decideVerification(
    String mechanicId, {
    required bool approve,
    String? reason,
  }) async {
    applications.removeWhere((row) => row.id == mechanicId);
    _audit(
      approve ? 'mechanic_verification_approve' : 'mechanic_verification_reject',
      mechanicId,
      reason ?? 'Approved mechanic application.',
    );
    return const Ok(null);
  }

  @override
  Future<Result<List<AdminBookingRow>>> listBookings({String? status, String? city}) async {
    return Ok(
      bookings
          .where((b) => (status == null || b.status == status) && (city == null || b.city == city))
          .toList(),
    );
  }

  @override
  Future<Result<AdminRevenue>> revenue(String window) async {
    return const Ok(
      AdminRevenue(
        gmvPaise: 50000,
        refundsPaise: 0,
        cashPaise: 0,
        onlinePaise: 50000,
        jobCount: 1,
      ),
    );
  }

  @override
  Future<Result<List<AdminCouponRow>>> listCoupons() async => Ok(coupons);

  @override
  Future<Result<AdminCouponRow>> createCoupon({required String code, required String title}) async {
    final row = AdminCouponRow(code: code.toUpperCase(), title: title, active: true, redemptionCount: 0);
    coupons.add(row);
    _audit('coupon_create', row.code, title);
    return Ok(row);
  }

  @override
  Future<Result<AdminCouponRow>> disableCoupon(String code) async {
    final index = coupons.indexWhere((c) => c.code == code);
    if (index < 0) return const Err(NotFound());
    final next = AdminCouponRow(
      code: coupons[index].code,
      title: coupons[index].title,
      active: false,
      redemptionCount: coupons[index].redemptionCount,
    );
    coupons[index] = next;
    _audit('coupon_disable', code, 'disabled');
    return Ok(next);
  }

  @override
  Future<Result<List<AdminDisputeRow>>> listDisputes() async => Ok(disputes);

  @override
  Future<Result<void>> addDisputeNote(String id, {required String note}) async {
    _audit('dispute_note', id, note);
    return const Ok(null);
  }

  @override
  Future<Result<void>> resolveDispute(
    String id, {
    required String resolution,
    required int amountPaise,
    required String note,
  }) async {
    disputes.removeWhere((d) => d.id == id);
    _audit('dispute_resolve', id, '$resolution $note');
    return const Ok(null);
  }

  @override
  Future<Result<List<AdminAuditRow>>> listAudit() async => Ok(audit);

  @override
  Future<Result<Map<String, int>>> analyticsCounts() async =>
      const Ok({'booking_submitted': 3, 'payment_succeeded': 2});

  void _audit(String action, String targetId, String summary) {
    audit.insert(
      0,
      AdminAuditRow(action: action, targetId: targetId, summary: summary, createdAt: DateTime.now()),
    );
  }
}
