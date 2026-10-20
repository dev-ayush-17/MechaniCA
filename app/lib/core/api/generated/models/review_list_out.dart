// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'review_out.dart';

part 'review_list_out.g.dart';

@JsonSerializable()
class ReviewListOut {
  const ReviewListOut({
    required this.items,
    required this.ratingAvg,
    required this.ratingCount,
  });
  
  factory ReviewListOut.fromJson(Map<String, Object?> json) => _$ReviewListOutFromJson(json);
  
  final List<ReviewOut> items;
  final num ratingAvg;
  final int ratingCount;

  Map<String, Object?> toJson() => _$ReviewListOutToJson(this);
}
