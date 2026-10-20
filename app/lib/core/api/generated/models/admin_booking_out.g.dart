// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_booking_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminBookingOut _$AdminBookingOutFromJson(Map<String, dynamic> json) =>
    AdminBookingOut(
      city: json['city'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerId: json['customerId'] as String,
      displayNumber: json['displayNumber'] as String,
      id: json['id'] as String,
      status: json['status'] as String,
      totalPaise: (json['totalPaise'] as num).toInt(),
    );

Map<String, dynamic> _$AdminBookingOutToJson(AdminBookingOut instance) =>
    <String, dynamic>{
      'city': instance.city,
      'createdAt': instance.createdAt.toIso8601String(),
      'customerId': instance.customerId,
      'displayNumber': instance.displayNumber,
      'id': instance.id,
      'status': instance.status,
      'totalPaise': instance.totalPaise,
    };
