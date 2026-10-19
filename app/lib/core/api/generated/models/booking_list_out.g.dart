// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingListOut _$BookingListOutFromJson(Map<String, dynamic> json) =>
    BookingListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => BookingOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookingListOutToJson(BookingListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
