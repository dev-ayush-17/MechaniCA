// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_review_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitReviewRequest _$SubmitReviewRequestFromJson(Map<String, dynamic> json) =>
    SubmitReviewRequest(
      bookingId: json['bookingId'] as String,
      stars: (json['stars'] as num).toInt(),
      photoPaths: (json['photoPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      text: json['text'] as String? ?? '',
    );

Map<String, dynamic> _$SubmitReviewRequestToJson(
        SubmitReviewRequest instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'photoPaths': instance.photoPaths,
      'stars': instance.stars,
      'text': instance.text,
    };
