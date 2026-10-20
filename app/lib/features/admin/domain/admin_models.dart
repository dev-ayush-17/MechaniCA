class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String status;
}

class AdminBookingRow {
  const AdminBookingRow({
    required this.id,
    required this.displayNumber,
    required this.status,
    required this.city,
    required this.createdAt,
    required this.totalPaise,
  });

  final String id;
  final String displayNumber;
  final String status;
  final String city;
  final DateTime createdAt;
  final int totalPaise;
}

class AdminApplicationRow {
  const AdminApplicationRow({
    required this.id,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String displayName;
  final String status;
}

class AdminCouponRow {
  const AdminCouponRow({
    required this.code,
    required this.title,
    required this.active,
    required this.redemptionCount,
  });

  final String code;
  final String title;
  final bool active;
  final int redemptionCount;
}

class AdminDisputeRow {
  const AdminDisputeRow({
    required this.id,
    required this.bookingId,
    required this.reason,
    required this.status,
  });

  final String id;
  final String bookingId;
  final String reason;
  final String status;
}

class AdminAuditRow {
  const AdminAuditRow({
    required this.action,
    required this.targetId,
    required this.summary,
    required this.createdAt,
  });

  final String action;
  final String targetId;
  final String summary;
  final DateTime createdAt;
}

class AdminRevenue {
  const AdminRevenue({
    required this.gmvPaise,
    required this.refundsPaise,
    required this.cashPaise,
    required this.onlinePaise,
    required this.jobCount,
  });

  final int gmvPaise;
  final int refundsPaise;
  final int cashPaise;
  final int onlinePaise;
  final int jobCount;
}
