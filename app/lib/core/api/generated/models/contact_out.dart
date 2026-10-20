// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'contact_out.g.dart';

@JsonSerializable()
class ContactOut {
  const ContactOut({
    required this.id,
    required this.name,
    required this.phoneE164,
  });
  
  factory ContactOut.fromJson(Map<String, Object?> json) => _$ContactOutFromJson(json);
  
  final String id;
  final String name;
  final String phoneE164;

  Map<String, Object?> toJson() => _$ContactOutToJson(this);
}
