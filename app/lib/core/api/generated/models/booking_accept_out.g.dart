// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_accept_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingAcceptOut _$BookingAcceptOutFromJson(Map<String, dynamic> json) =>
    BookingAcceptOut(
      id: json['id'] as String,
      mechanicId: json['mechanicId'] as String?,
      status: json['status'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$BookingAcceptOutToJson(BookingAcceptOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mechanicId': instance.mechanicId,
      'status': instance.status,
      'version': instance.version,
    };
