enum BookingStatus {
  pending,
  confirmed,
  mechanicAssigned,
  pickedUp,
  inWorkshop,
  inProgress,
  qualityCheck,
  outForDelivery,
  completed,
  cancelled,
  rescheduled,
}

enum ServiceType {
  pickupDrop,
  visitWorkshop,
}

class BookingModel {
  final String id;
  final String userId;
  final String bikeId;
  final String bikeName;
  final String bikeNumber;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final BookingStatus status;
  final ServiceType serviceType;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String? pickupAddress;
  final String? workshopAddress;
  final String? couponCode;
  final double discount;
  final double pickupCharges;
  final double gst;
  final double totalAmount;
  final String paymentMethod;
  final String? mechanicId;
  final String? mechanicName;
  final String? mechanicPhone;
  final String? mechanicRating;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final int? rating;
  final String? review;
  final List<String> statusTimeline;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.bikeName,
    required this.bikeNumber,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.status,
    required this.serviceType,
    required this.scheduledDate,
    required this.scheduledTime,
    this.pickupAddress,
    this.workshopAddress,
    this.couponCode,
    required this.discount,
    required this.pickupCharges,
    required this.gst,
    required this.totalAmount,
    required this.paymentMethod,
    this.mechanicId,
    this.mechanicName,
    this.mechanicPhone,
    this.mechanicRating,
    required this.createdAt,
    this.completedAt,
    this.cancellationReason,
    this.rating,
    this.review,
    required this.statusTimeline,
  });

  String get bookingNumber => 'MC${id.substring(0, 8).toUpperCase()}';

  bool get isActive => [
        BookingStatus.confirmed,
        BookingStatus.mechanicAssigned,
        BookingStatus.pickedUp,
        BookingStatus.inWorkshop,
        BookingStatus.inProgress,
        BookingStatus.qualityCheck,
        BookingStatus.outForDelivery,
      ].contains(status);

  BookingModel copyWith({
    String? id,
    String? userId,
    String? bikeId,
    String? bikeName,
    String? bikeNumber,
    String? serviceId,
    String? serviceName,
    double? servicePrice,
    BookingStatus? status,
    ServiceType? serviceType,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? pickupAddress,
    String? workshopAddress,
    String? couponCode,
    double? discount,
    double? pickupCharges,
    double? gst,
    double? totalAmount,
    String? paymentMethod,
    String? mechanicId,
    String? mechanicName,
    String? mechanicPhone,
    String? mechanicRating,
    DateTime? createdAt,
    DateTime? completedAt,
    String? cancellationReason,
    int? rating,
    String? review,
    List<String>? statusTimeline,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bikeId: bikeId ?? this.bikeId,
      bikeName: bikeName ?? this.bikeName,
      bikeNumber: bikeNumber ?? this.bikeNumber,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      workshopAddress: workshopAddress ?? this.workshopAddress,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
      pickupCharges: pickupCharges ?? this.pickupCharges,
      gst: gst ?? this.gst,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mechanicId: mechanicId ?? this.mechanicId,
      mechanicName: mechanicName ?? this.mechanicName,
      mechanicPhone: mechanicPhone ?? this.mechanicPhone,
      mechanicRating: mechanicRating ?? this.mechanicRating,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      statusTimeline: statusTimeline ?? this.statusTimeline,
    );
  }
}
