// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_review_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditReviewRequest _$EditReviewRequestFromJson(Map<String, dynamic> json) =>
    EditReviewRequest(
      stars: (json['stars'] as num).toInt(),
      text: json['text'] as String? ?? '',
    );

Map<String, dynamic> _$EditReviewRequestToJson(EditReviewRequest instance) =>
    <String, dynamic>{
      'stars': instance.stars,
      'text': instance.text,
    };
