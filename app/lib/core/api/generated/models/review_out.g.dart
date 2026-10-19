// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewOut _$ReviewOutFromJson(Map<String, dynamic> json) => ReviewOut(
      bookingId: json['bookingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      id: json['id'] as String,
      mechanicId: json['mechanicId'] as String,
      photoPaths: (json['photoPaths'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      stars: (json['stars'] as num).toInt(),
      status: json['status'] as String,
      text: json['text'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewOutToJson(ReviewOut instance) => <String, dynamic>{
      'bookingId': instance.bookingId,
      'createdAt': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'mechanicId': instance.mechanicId,
      'photoPaths': instance.photoPaths,
      'stars': instance.stars,
      'status': instance.status,
      'text': instance.text,
      'version': instance.version,
    };
