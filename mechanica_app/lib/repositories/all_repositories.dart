import '../models/app_models.dart';
import '../models/user_model.dart';
import '../mock/mock_data.dart';
import '../mock/mock_delay.dart';

// ─── WALLET REPOSITORY ────────────────────────────────────────────────────────

abstract class WalletRepository {
  Future<double> getBalance(String userId);
  Future<List<WalletTransactionModel>> getTransactions(String userId);
  Future<double> addMoney(String userId, double amount);
}

class MockWalletRepository implements WalletRepository {
  double _balance = mockUser.walletBalance;
  final List<WalletTransactionModel> _transactions = List.from(mockTransactions);

  @override
  Future<double> getBalance(String userId) async {
    await MockDelay.short();
    return _balance;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    await MockDelay.wait();
    return _transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<double> addMoney(String userId, double amount) async {
    await MockDelay.long();
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'Added to Wallet',
        subtitle: 'Via UPI',
        amount: amount,
        isCredit: true,
        date: DateTime.now(),
        type: 'topup',
      ),
    );
    return _balance;
  }
}

// ─── OFFER REPOSITORY ─────────────────────────────────────────────────────────

abstract class OfferRepository {
  Future<List<OfferModel>> getOffers();
  Future<OfferModel?> validateCoupon(String code, double orderAmount);
}

class MockOfferRepository implements OfferRepository {
  @override
  Future<List<OfferModel>> getOffers() async {
    await MockDelay.wait();
    return mockOffers;
  }

  @override
  Future<OfferModel?> validateCoupon(String code, double orderAmount) async {
    await MockDelay.wait();
    try {
      final offer = mockOffers.firstWhere(
        (o) => o.couponCode.toUpperCase() == code.toUpperCase() && o.isActive,
      );
      if (orderAmount >= offer.minOrderValue) return offer;
      throw Exception('Minimum order value not met');
    } catch (_) {
      return null;
    }
  }
}

// ─── MEMBERSHIP REPOSITORY ────────────────────────────────────────────────────

abstract class MembershipRepository {
  Future<List<MembershipPlanModel>> getPlans();
  Future<UserModel> upgradeMembership(String userId, String planId);
}

class MockMembershipRepository implements MembershipRepository {
  @override
  Future<List<MembershipPlanModel>> getPlans() async {
    await MockDelay.wait();
    return mockMembershipPlans;
  }

  @override
  Future<UserModel> upgradeMembership(String userId, String planId) async {
    await MockDelay.long();
    final plan = mockMembershipPlans.firstWhere((p) => p.id == planId);
    return mockUser.copyWith(membershipPlan: plan.name.toLowerCase());
  }
}

// ─── NOTIFICATION REPOSITORY ──────────────────────────────────────────────────

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
}

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _notifications = List.from(mockNotifications);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    await MockDelay.wait();
    return _notifications.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await MockDelay.short();
    final n = _notifications.firstWhere((n) => n.id == notificationId);
    n.isRead = true;
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await MockDelay.short();
    for (final n in _notifications.where((n) => n.userId == userId)) {
      n.isRead = true;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await MockDelay.short();
    _notifications.removeWhere((n) => n.id == notificationId);
  }
}

// ─── FUEL REPOSITORY ──────────────────────────────────────────────────────────

abstract class FuelRepository {
  Future<List<FuelLogModel>> getFuelLogs(String bikeId);
  Future<FuelLogModel> addFuelLog(FuelLogModel log);
  Future<void> deleteFuelLog(String logId);
}

class MockFuelRepository implements FuelRepository {
  final List<FuelLogModel> _logs = List.from(mockFuelLogs);

  @override
  Future<List<FuelLogModel>> getFuelLogs(String bikeId) async {
    await MockDelay.wait();
    return _logs.where((l) => l.bikeId == bikeId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<FuelLogModel> addFuelLog(FuelLogModel log) async {
    await MockDelay.wait();
    _logs.insert(0, log);
    return log;
  }

  @override
  Future<void> deleteFuelLog(String logId) async {
    await MockDelay.short();
    _logs.removeWhere((l) => l.id == logId);
  }
}

// ─── HEALTH REPOSITORY ────────────────────────────────────────────────────────

abstract class HealthRepository {
  Future<HealthScoreModel> getHealthScore(String bikeId);
}

class MockHealthRepository implements HealthRepository {
  @override
  Future<HealthScoreModel> getHealthScore(String bikeId) async {
    await MockDelay.wait();
    return mockHealthScore;
  }
}

// ─── DOCUMENT REPOSITORY ──────────────────────────────────────────────────────

abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocuments(String bikeId);
  Future<DocumentModel> uploadDocument(DocumentModel doc);
  Future<void> deleteDocument(String docId);
}

class MockDocumentRepository implements DocumentRepository {
  final List<DocumentModel> _docs = List.from(mockDocuments);

  @override
  Future<List<DocumentModel>> getDocuments(String bikeId) async {
    await MockDelay.wait();
    return _docs.where((d) => d.bikeId == bikeId).toList();
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentModel doc) async {
    await MockDelay.long();
    _docs.add(doc);
    return doc;
  }

  @override
  Future<void> deleteDocument(String docId) async {
    await MockDelay.short();
    _docs.removeWhere((d) => d.id == docId);
  }
}

// ─── SUPPORT REPOSITORY ───────────────────────────────────────────────────────

abstract class SupportRepository {
  Future<List<SupportTicketModel>> getTickets(String userId);
  Future<SupportTicketModel> createTicket(SupportTicketModel ticket);
  Future<SupportTicketModel> addMessage(String ticketId, String message);
}

class MockSupportRepository implements SupportRepository {
  final List<SupportTicketModel> _tickets = List.from(mockTickets);

  @override
  Future<List<SupportTicketModel>> getTickets(String userId) async {
    await MockDelay.wait();
    return _tickets.where((t) => t.userId == userId).toList();
  }

  @override
  Future<SupportTicketModel> createTicket(SupportTicketModel ticket) async {
    await MockDelay.wait();
    _tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<SupportTicketModel> addMessage(String ticketId, String message) async {
    await MockDelay.short();
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw Exception('Ticket not found');
    final ticket = _tickets[idx];
    final newMsg = TicketMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      sentAt: DateTime.now(),
    );
    final updated = SupportTicketModel(
      id: ticket.id,
      userId: ticket.userId,
      subject: ticket.subject,
      description: ticket.description,
      status: ticket.status,
      category: ticket.category,
      createdAt: ticket.createdAt,
      resolvedAt: ticket.resolvedAt,
      messages: [...ticket.messages, newMsg],
    );
    _tickets[idx] = updated;
    return updated;
  }
}

// ─── PROFILE REPOSITORY ───────────────────────────────────────────────────────

abstract class ProfileRepository {
  Future<UserModel> getProfile(String userId);
  Future<UserModel> updateProfile(UserModel user);
  Future<List<AddressModel>> getAddresses(String userId);
  Future<AddressModel> addAddress(AddressModel address);
  Future<void> deleteAddress(String addressId);
}

class MockProfileRepository implements ProfileRepository {
  UserModel _user = mockUser;
  final List<AddressModel> _addresses = List.from(mockAddresses);

  @override
  Future<UserModel> getProfile(String userId) async {
    await MockDelay.short();
    return _user;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await MockDelay.wait();
    _user = user;
    return _user;
  }

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    await MockDelay.wait();
    return _addresses;
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    await MockDelay.wait();
    _addresses.add(address);
    return address;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await MockDelay.short();
    _addresses.removeWhere((a) => a.id == addressId);
  }
}

// ─── INVOICE REPOSITORY ───────────────────────────────────────────────────────

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> getInvoices(String userId);
  Future<InvoiceModel> getInvoiceByBooking(String bookingId);
}

class MockInvoiceRepository implements InvoiceRepository {
  @override
  Future<List<InvoiceModel>> getInvoices(String userId) async {
    await MockDelay.wait();
    return mockInvoices.where((i) => i.userId == userId).toList();
  }

  @override
  Future<InvoiceModel> getInvoiceByBooking(String bookingId) async {
    await MockDelay.short();
    return mockInvoices.firstWhere((i) => i.bookingId == bookingId);
  }
}

// ─── INSPECTION REPOSITORY ────────────────────────────────────────────────────

abstract class InspectionRepository {
  Future<InspectionModel> getInspectionByBooking(String bookingId);
}

class MockInspectionRepository implements InspectionRepository {
  @override
  Future<InspectionModel> getInspectionByBooking(String bookingId) async {
    await MockDelay.wait();
    return mockInspection;
  }
}
