// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reconcile_out.g.dart';

@JsonSerializable()
class ReconcileOut {
  const ReconcileOut({
    required this.applied,
  });
  
  factory ReconcileOut.fromJson(Map<String, Object?> json) => _$ReconcileOutFromJson(json);
  
  final int applied;

  Map<String, Object?> toJson() => _$ReconcileOutToJson(this);
}
