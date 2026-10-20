// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'edit_review_request.g.dart';

@JsonSerializable()
class EditReviewRequest {
  const EditReviewRequest({
    required this.stars,
    this.text = '',
  });
  
  factory EditReviewRequest.fromJson(Map<String, Object?> json) => _$EditReviewRequestFromJson(json);
  
  final int stars;
  final String text;

  Map<String, Object?> toJson() => _$EditReviewRequestToJson(this);
}
