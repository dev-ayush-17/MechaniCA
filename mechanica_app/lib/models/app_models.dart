class InvoiceModel {
  final String id;
  final String bookingId;
  final String userId;
  final String bikeNumber;
  final String serviceName;
  final DateTime date;
  final double serviceCharge;
  final double pickupCharges;
  final double partsCost;
  final double discount;
  final double gst;
  final double totalAmount;
  final String paymentMethod;
  final bool isPaid;
  final List<InvoiceItem> items;

  const InvoiceModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.bikeNumber,
    required this.serviceName,
    required this.date,
    required this.serviceCharge,
    required this.pickupCharges,
    required this.partsCost,
    required this.discount,
    required this.gst,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.items,
  });

  String get invoiceNumber => 'INV${id.substring(0, 8).toUpperCase()}';
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double price;

  const InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

class WalletTransactionModel {
  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final DateTime date;
  final String type; // 'cashback', 'payment', 'refund', 'referral', 'topup'

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.type,
  });
}

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String couponCode;
  final int discountPercent;
  final double maxDiscount;
  final double minOrderValue;
  final DateTime validTill;
  final String category; // 'service', 'membership', 'referral', 'cashback'
  final bool isActive;
  final String? imageUrl;
  final String badgeText;

  const OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.couponCode,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.validTill,
    required this.category,
    required this.isActive,
    this.imageUrl,
    required this.badgeText,
  });
}

class MembershipPlanModel {
  final String id;
  final String name; // 'silver', 'gold', 'platinum'
  final double price;
  final String duration; // '3 months', '6 months', '1 year'
  final List<String> benefits;
  final int freeServices;
  final int discountPercent;
  final bool hasPrioritySupport;
  final bool hasFreePickup;
  final String badgeColor;

  const MembershipPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.benefits,
    required this.freeServices,
    required this.discountPercent,
    required this.hasPrioritySupport,
    required this.hasFreePickup,
    required this.badgeColor,
  });
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'booking', 'offer', 'wallet', 'emergency', 'system'
  final String? actionRoute;
  final String? actionId;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.actionRoute,
    this.actionId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      actionRoute: actionRoute,
      actionId: actionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class FuelLogModel {
  final String id;
  final String bikeId;
  final DateTime date;
  final double litres;
  final double pricePerLitre;
  final double totalCost;
  final int odometer;
  final double? mileage; // km/litre
  final String? stationName;

  const FuelLogModel({
    required this.id,
    required this.bikeId,
    required this.date,
    required this.litres,
    required this.pricePerLitre,
    required this.totalCost,
    required this.odometer,
    this.mileage,
    this.stationName,
  });
}

class HealthScoreModel {
  final String bikeId;
  final int overallScore; // 0-100
  final String condition; // 'Excellent', 'Good', 'Fair', 'Poor'
  final HealthIndicator engine;
  final HealthIndicator brakes;
  final HealthIndicator battery;
  final HealthIndicator tyres;
  final HealthIndicator oil;
  final List<String> recommendations;
  final DateTime lastChecked;

  const HealthScoreModel({
    required this.bikeId,
    required this.overallScore,
    required this.condition,
    required this.engine,
    required this.brakes,
    required this.battery,
    required this.tyres,
    required this.oil,
    required this.recommendations,
    required this.lastChecked,
  });
}

class HealthIndicator {
  final String name;
  final int score; // 0-100
  final String status; // 'Good', 'Moderate', 'Poor'
  final String description;

  const HealthIndicator({
    required this.name,
    required this.score,
    required this.status,
    required this.description,
  });
}

class DocumentModel {
  final String id;
  final String bikeId;
  final String type; // 'insurance', 'rc', 'puc', 'license'
  final String title;
  final String? documentNumber;
  final DateTime? expiryDate;
  final String status; // 'valid', 'expiring', 'expired'
  final String? fileUrl;
  final DateTime uploadedAt;

  const DocumentModel({
    required this.id,
    required this.bikeId,
    required this.type,
    required this.title,
    this.documentNumber,
    this.expiryDate,
    required this.status,
    this.fileUrl,
    required this.uploadedAt,
  });
}

class SupportTicketModel {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String category; // 'booking', 'billing', 'technical', 'general'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<TicketMessage> messages;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.category,
    required this.createdAt,
    this.resolvedAt,
    required this.messages,
  });
}

class TicketMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime sentAt;

  const TicketMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.sentAt,
  });
}

class AddressModel {
  final String id;
  final String label; // 'Home', 'Work', 'Other'
  final String fullAddress;
  final String landmark;
  final String pincode;
  final String city;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.landmark,
    required this.pincode,
    required this.city,
    required this.isDefault,
  });

  AddressModel copyWith({bool? isDefault}) => AddressModel(
        id: id,
        label: label,
        fullAddress: fullAddress,
        landmark: landmark,
        pincode: pincode,
        city: city,
        isDefault: isDefault ?? this.isDefault,
      );
}

class InspectionModel {
  final String id;
  final String bookingId;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final List<String> observations;
  final List<String> recommendations;
  final List<PartChanged> partsChanged;
  final String mechanicNotes;
  final DateTime date;

  const InspectionModel({
    required this.id,
    required this.bookingId,
    required this.beforePhotos,
    required this.afterPhotos,
    required this.observations,
    required this.recommendations,
    required this.partsChanged,
    required this.mechanicNotes,
    required this.date,
  });
}

class PartChanged {
  final String name;
  final int quantity;
  final double price;

  const PartChanged({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
