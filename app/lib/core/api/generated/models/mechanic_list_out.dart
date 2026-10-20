// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mechanic_out.dart';

part 'mechanic_list_out.g.dart';

@JsonSerializable()
class MechanicListOut {
  const MechanicListOut({
    required this.items,
  });
  
  factory MechanicListOut.fromJson(Map<String, Object?> json) => _$MechanicListOutFromJson(json);
  
  final List<MechanicOut> items;

  Map<String, Object?> toJson() => _$MechanicListOutToJson(this);
}
