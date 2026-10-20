// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_booking_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminBookingListOut _$AdminBookingListOutFromJson(Map<String, dynamic> json) =>
    AdminBookingListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => AdminBookingOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AdminBookingListOutToJson(
        AdminBookingListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
