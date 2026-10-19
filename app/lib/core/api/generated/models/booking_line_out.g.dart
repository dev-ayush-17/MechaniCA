// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_line_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingLineOut _$BookingLineOutFromJson(Map<String, dynamic> json) =>
    BookingLineOut(
      amountPaise: (json['amountPaise'] as num).toInt(),
      gstPaise: (json['gstPaise'] as num).toInt(),
      id: json['id'] as String,
      kind: json['kind'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$BookingLineOutToJson(BookingLineOut instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'gstPaise': instance.gstPaise,
      'id': instance.id,
      'kind': instance.kind,
      'name': instance.name,
      'status': instance.status,
    };
