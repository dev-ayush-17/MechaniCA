import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/bike_model.dart';
import '../models/app_models.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/bike_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/all_repositories.dart';
import '../mock/mock_data.dart';

// ─── REPOSITORY PROVIDERS ─────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
final bikeRepositoryProvider = Provider<BikeRepository>((ref) => MockBikeRepository());
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) => MockServiceRepository());
final bookingRepositoryProvider = Provider<BookingRepository>((ref) => MockBookingRepository());
final walletRepositoryProvider = Provider<WalletRepository>((ref) => MockWalletRepository());
final offerRepositoryProvider = Provider<OfferRepository>((ref) => MockOfferRepository());
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) => MockMembershipRepository());
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => MockNotificationRepository());
final fuelRepositoryProvider = Provider<FuelRepository>((ref) => MockFuelRepository());
final healthRepositoryProvider = Provider<HealthRepository>((ref) => MockHealthRepository());
final documentRepositoryProvider = Provider<DocumentRepository>((ref) => MockDocumentRepository());
final supportRepositoryProvider = Provider<SupportRepository>((ref) => MockSupportRepository());
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => MockProfileRepository());
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) => MockInvoiceRepository());
final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) => MockInspectionRepository());

// ─── AUTH PROVIDER ────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.loginWithPhone(phone, otp);
      state = state.copyWith(isLoading: false, user: user, isLoggedIn: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid OTP. Please try again.');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.loginWithGoogle();
      state = state.copyWith(isLoading: false, user: user, isLoggedIn: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

// ─── BIKE PROVIDER ────────────────────────────────────────────────────────────

class BikeNotifier extends StateNotifier<AsyncValue<List<BikeModel>>> {
  final BikeRepository _repo;
  BikeNotifier(this._repo) : super(const AsyncLoading());

  Future<void> loadBikes(String userId) async {
    state = const AsyncLoading();
    try {
      final bikes = await _repo.getBikes(userId);
      state = AsyncData(bikes);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> addBike(BikeModel bike) async {
    try {
      final added = await _repo.addBike(bike);
      state.whenData((bikes) {
        state = AsyncData([...bikes, added]);
      });
    } catch (_) {}
  }

  Future<void> updateBike(BikeModel bike) async {
    try {
      await _repo.updateBike(bike);
      state.whenData((bikes) {
        state = AsyncData(bikes.map((b) => b.id == bike.id ? bike : b).toList());
      });
    } catch (_) {}
  }

  Future<void> deleteBike(String bikeId) async {
    try {
      await _repo.deleteBike(bikeId);
      state.whenData((bikes) {
        state = AsyncData(bikes.where((b) => b.id != bikeId).toList());
      });
    } catch (_) {}
  }
}

final bikeProvider = StateNotifierProvider<BikeNotifier, AsyncValue<List<BikeModel>>>(
  (ref) => BikeNotifier(ref.watch(bikeRepositoryProvider)),
);

// ─── SERVICE PROVIDER ─────────────────────────────────────────────────────────

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getServices();
});

// ─── BOOKING PROVIDER ─────────────────────────────────────────────────────────

class BookingNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final BookingRepository _repo;
  BookingNotifier(this._repo) : super(const AsyncLoading());

  Future<void> loadBookings(String userId) async {
    state = const AsyncLoading();
    try {
      final bookings = await _repo.getBookings(userId);
      state = AsyncData(bookings);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<BookingModel?> createBooking(BookingModel booking) async {
    try {
      final created = await _repo.createBooking(booking);
      state.whenData((list) {
        state = AsyncData([created, ...list]);
      });
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _repo.cancelBooking(bookingId, reason);
      state.whenData((list) {
        state = AsyncData(
          list.map((b) => b.id == bookingId
              ? b.copyWith(status: BookingStatus.cancelled, cancellationReason: reason)
              : b).toList(),
        );
      });
    } catch (_) {}
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    try {
      await _repo.updateBookingStatus(bookingId, status);
      state.whenData((list) {
        state = AsyncData(
          list.map((b) => b.id == bookingId ? b.copyWith(status: status) : b).toList(),
        );
      });
    } catch (_) {}
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingNotifier(ref.watch(bookingRepositoryProvider)),
);

// ─── BOOKING FLOW STATE ───────────────────────────────────────────────────────

class BookingFlowState {
  final BikeModel? selectedBike;
  final ServiceModel? selectedService;
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isPickupDrop;
  final String? pickupAddress;
  final String? couponCode;
  final double discount;
  final String paymentMethod;

  const BookingFlowState({
    this.selectedBike,
    this.selectedService,
    this.selectedDate,
    this.selectedTime,
    this.isPickupDrop = true,
    this.pickupAddress,
    this.couponCode,
    this.discount = 0.0,
    this.paymentMethod = 'UPI',
  });

  double get pickupCharges => isPickupDrop ? 100.0 : 0.0;
  double get subtotal => (selectedService?.price ?? 0) + pickupCharges;
  double get gst => (subtotal - discount) * 0.18;
  double get total => subtotal - discount + gst;

  BookingFlowState copyWith({
    BikeModel? selectedBike,
    ServiceModel? selectedService,
    DateTime? selectedDate,
    String? selectedTime,
    bool? isPickupDrop,
    String? pickupAddress,
    String? couponCode,
    double? discount,
    String? paymentMethod,
  }) {
    return BookingFlowState(
      selectedBike: selectedBike ?? this.selectedBike,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      isPickupDrop: isPickupDrop ?? this.isPickupDrop,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void selectBike(BikeModel bike) => state = state.copyWith(selectedBike: bike);
  void selectService(ServiceModel service) => state = state.copyWith(selectedService: service);
  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void selectTime(String time) => state = state.copyWith(selectedTime: time);
  void setPickupDrop(bool v) => state = state.copyWith(isPickupDrop: v);
  void setPickupAddress(String addr) => state = state.copyWith(pickupAddress: addr);
  void setPaymentMethod(String method) => state = state.copyWith(paymentMethod: method);
  void applyCoupon(String code, double discount) =>
      state = state.copyWith(couponCode: code, discount: discount);
  void removeCoupon() => state = state.copyWith(couponCode: null, discount: 0.0);
  void reset() => state = const BookingFlowState();
}

final bookingFlowProvider = StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(),
);

// ─── WALLET PROVIDER ──────────────────────────────────────────────────────────

class WalletState {
  final double balance;
  final List<WalletTransactionModel> transactions;
  final bool isLoading;

  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.isLoading = false,
  });

  WalletState copyWith({double? balance, List<WalletTransactionModel>? transactions, bool? isLoading}) =>
      WalletState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
      );
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;
  WalletNotifier(this._repo) : super(const WalletState(isLoading: true));

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true);
    final balance = await _repo.getBalance(userId);
    final transactions = await _repo.getTransactions(userId);
    state = WalletState(balance: balance, transactions: transactions, isLoading: false);
  }

  Future<void> addMoney(String userId, double amount) async {
    state = state.copyWith(isLoading: true);
    final newBalance = await _repo.addMoney(userId, amount);
    final transactions = await _repo.getTransactions(userId);
    state = WalletState(balance: newBalance, transactions: transactions, isLoading: false);
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(ref.watch(walletRepositoryProvider)),
);

// ─── OFFER PROVIDER ───────────────────────────────────────────────────────────

final offersProvider = FutureProvider<List<OfferModel>>((ref) async {
  return ref.watch(offerRepositoryProvider).getOffers();
});

// ─── MEMBERSHIP PROVIDER ──────────────────────────────────────────────────────

final membershipPlansProvider = FutureProvider<List<MembershipPlanModel>>((ref) async {
  return ref.watch(membershipRepositoryProvider).getPlans();
});

// ─── NOTIFICATION PROVIDER ────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repo;
  NotificationNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String userId) async {
    state = const AsyncLoading();
    try {
      final list = await _repo.getNotifications(userId);
      state = AsyncData(list);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markAsRead(id);
    state.whenData((list) {
      state = AsyncData(
        list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    });
  }

  Future<void> markAllRead(String userId) async {
    await _repo.markAllAsRead(userId);
    state.whenData((list) {
      state = AsyncData(list.map((n) => n.copyWith(isRead: true)).toList());
    });
  }

  Future<void> delete(String id) async {
    await _repo.deleteNotification(id);
    state.whenData((list) {
      state = AsyncData(list.where((n) => n.id != id).toList());
    });
  }

  int get unreadCount {
    return state.whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ?? 0;
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationNotifier(ref.watch(notificationRepositoryProvider)),
);

// ─── FUEL PROVIDER ────────────────────────────────────────────────────────────

class FuelNotifier extends StateNotifier<AsyncValue<List<FuelLogModel>>> {
  final FuelRepository _repo;
  FuelNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String bikeId) async {
    state = const AsyncLoading();
    try {
      final logs = await _repo.getFuelLogs(bikeId);
      state = AsyncData(logs);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> addLog(FuelLogModel log) async {
    try {
      final added = await _repo.addFuelLog(log);
      state.whenData((logs) {
        state = AsyncData([added, ...logs]);
      });
    } catch (_) {}
  }

  Future<void> deleteLog(String logId) async {
    try {
      await _repo.deleteFuelLog(logId);
      state.whenData((logs) {
        state = AsyncData(logs.where((l) => l.id != logId).toList());
      });
    } catch (_) {}
  }
}

final fuelProvider = StateNotifierProvider<FuelNotifier, AsyncValue<List<FuelLogModel>>>(
  (ref) => FuelNotifier(ref.watch(fuelRepositoryProvider)),
);

// ─── HEALTH PROVIDER ──────────────────────────────────────────────────────────

final healthScoreProvider = FutureProvider.family<HealthScoreModel, String>((ref, bikeId) async {
  return ref.watch(healthRepositoryProvider).getHealthScore(bikeId);
});

// ─── DOCUMENT PROVIDER ────────────────────────────────────────────────────────

class DocumentNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  final DocumentRepository _repo;
  DocumentNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String bikeId) async {
    state = const AsyncLoading();
    try {
      final docs = await _repo.getDocuments(bikeId);
      state = AsyncData(docs);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> upload(DocumentModel doc) async {
    try {
      final added = await _repo.uploadDocument(doc);
      state.whenData((docs) {
        state = AsyncData([...docs, added]);
      });
    } catch (_) {}
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, AsyncValue<List<DocumentModel>>>(
  (ref) => DocumentNotifier(ref.watch(documentRepositoryProvider)),
);

// ─── SUPPORT PROVIDER ─────────────────────────────────────────────────────────

class SupportNotifier extends StateNotifier<AsyncValue<List<SupportTicketModel>>> {
  final SupportRepository _repo;
  SupportNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String userId) async {
    state = const AsyncLoading();
    try {
      final tickets = await _repo.getTickets(userId);
      state = AsyncData(tickets);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> createTicket(SupportTicketModel ticket) async {
    try {
      final created = await _repo.createTicket(ticket);
      state.whenData((list) {
        state = AsyncData([created, ...list]);
      });
    } catch (_) {}
  }
}

final supportProvider = StateNotifierProvider<SupportNotifier, AsyncValue<List<SupportTicketModel>>>(
  (ref) => SupportNotifier(ref.watch(supportRepositoryProvider)),
);

// ─── PROFILE PROVIDER ─────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel>> {
  final ProfileRepository _repo;
  ProfileNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String userId) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.getProfile(userId);
      state = AsyncData(user);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> update(UserModel user) async {
    try {
      final updated = await _repo.updateProfile(user);
      state = AsyncData(updated);
    } catch (_) {}
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel>>(
  (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider)),
);

// ─── SELECTED BIKE PROVIDER ────────────────────────────────────────────────────

final selectedBikeProvider = StateProvider<BikeModel?>((ref) {
  return mockBikes.first;
});

// ─── INVOICE PROVIDER ─────────────────────────────────────────────────────────

final invoicesProvider = FutureProvider.family<List<InvoiceModel>, String>((ref, userId) async {
  return ref.watch(invoiceRepositoryProvider).getInvoices(userId);
});

// ─── INSPECTION PROVIDER ──────────────────────────────────────────────────────

final inspectionProvider = FutureProvider.family<InspectionModel, String>((ref, bookingId) async {
  return ref.watch(inspectionRepositoryProvider).getInspectionByBooking(bookingId);
});

// ─── TRACKING SIMULATION PROVIDER ────────────────────────────────────────────

class TrackingState {
  final int currentStepIndex;
  final bool isCompleted;

  const TrackingState({this.currentStepIndex = 3, this.isCompleted = false});

  TrackingState copyWith({int? currentStepIndex, bool? isCompleted}) => TrackingState(
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(),
);

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  void advance() {
    if (state.currentStepIndex < 6) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  void reset() => state = const TrackingState();
}

// ─── ADDRESSES PROVIDER ───────────────────────────────────────────────────────

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final ProfileRepository _repo;
  AddressNotifier(this._repo) : super(const AsyncLoading());

  Future<void> load(String userId) async {
    state = const AsyncLoading();
    try {
      final addresses = await _repo.getAddresses(userId);
      state = AsyncData(addresses);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> add(AddressModel address) async {
    try {
      final added = await _repo.addAddress(address);
      state.whenData((list) {
        state = AsyncData([...list, added]);
      });
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteAddress(id);
      state.whenData((list) {
        state = AsyncData(list.where((a) => a.id != id).toList());
      });
    } catch (_) {}
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>(
  (ref) => AddressNotifier(ref.watch(profileRepositoryProvider)),
);
