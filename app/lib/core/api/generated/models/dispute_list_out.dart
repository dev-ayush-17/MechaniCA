// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispute_out.dart';

part 'dispute_list_out.g.dart';

@JsonSerializable()
class DisputeListOut {
  const DisputeListOut({
    required this.items,
  });
  
  factory DisputeListOut.fromJson(Map<String, Object?> json) => _$DisputeListOutFromJson(json);
  
  final List<DisputeOut> items;

  Map<String, Object?> toJson() => _$DisputeListOutToJson(this);
}
