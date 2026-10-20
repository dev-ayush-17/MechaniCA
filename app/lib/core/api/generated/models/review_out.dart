// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review_out.g.dart';

@JsonSerializable()
class ReviewOut {
  const ReviewOut({
    required this.bookingId,
    required this.createdAt,
    required this.id,
    required this.mechanicId,
    required this.photoPaths,
    required this.stars,
    required this.status,
    required this.text,
    required this.version,
  });
  
  factory ReviewOut.fromJson(Map<String, Object?> json) => _$ReviewOutFromJson(json);
  
  final String bookingId;
  final DateTime createdAt;
  final String id;
  final String mechanicId;
  final List<String> photoPaths;
  final int stars;
  final String status;
  final String text;
  final int version;

  Map<String, Object?> toJson() => _$ReviewOutToJson(this);
}
