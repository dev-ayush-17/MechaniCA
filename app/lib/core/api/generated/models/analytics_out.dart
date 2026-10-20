// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'analytics_out.g.dart';

@JsonSerializable()
class AnalyticsOut {
  const AnalyticsOut({
    required this.counts,
  });
  
  factory AnalyticsOut.fromJson(Map<String, Object?> json) => _$AnalyticsOutFromJson(json);
  
  final Map<String, int> counts;

  Map<String, Object?> toJson() => _$AnalyticsOutToJson(this);
}
