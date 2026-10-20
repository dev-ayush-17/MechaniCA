// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'submit_review_request.g.dart';

@JsonSerializable()
class SubmitReviewRequest {
  const SubmitReviewRequest({
    required this.bookingId,
    required this.stars,
    this.photoPaths = const [],
    this.text = '',
  });
  
  factory SubmitReviewRequest.fromJson(Map<String, Object?> json) => _$SubmitReviewRequestFromJson(json);
  
  final String bookingId;
  final List<String> photoPaths;
  final int stars;
  final String text;

  Map<String, Object?> toJson() => _$SubmitReviewRequestToJson(this);
}
