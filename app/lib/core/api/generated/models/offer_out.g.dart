// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferOut _$OfferOutFromJson(Map<String, dynamic> json) => OfferOut(
      attempt: (json['attempt'] as num).toInt(),
      bookingId: json['bookingId'] as String,
      distanceKm: json['distanceKm'] as num,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      id: json['id'] as String,
      mechanicId: json['mechanicId'] as String,
      score: json['score'] as num,
      serviceName: json['serviceName'] as String,
      status: json['status'] as String,
      totalPaise: (json['totalPaise'] as num).toInt(),
      vehicleType: json['vehicleType'] as String? ?? '',
    );

Map<String, dynamic> _$OfferOutToJson(OfferOut instance) => <String, dynamic>{
      'attempt': instance.attempt,
      'bookingId': instance.bookingId,
      'distanceKm': instance.distanceKm,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'id': instance.id,
      'mechanicId': instance.mechanicId,
      'score': instance.score,
      'serviceName': instance.serviceName,
      'status': instance.status,
      'totalPaise': instance.totalPaise,
      'vehicleType': instance.vehicleType,
    };
