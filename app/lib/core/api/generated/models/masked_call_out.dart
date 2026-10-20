// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'masked_call_out.g.dart';

@JsonSerializable()
class MaskedCallOut {
  const MaskedCallOut({
    required this.dialNumber,
    required this.expiresAt,
  });
  
  factory MaskedCallOut.fromJson(Map<String, Object?> json) => _$MaskedCallOutFromJson(json);
  
  final String dialNumber;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => _$MaskedCallOutToJson(this);
}
