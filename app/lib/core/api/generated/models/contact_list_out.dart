// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'contact_out.dart';

part 'contact_list_out.g.dart';

@JsonSerializable()
class ContactListOut {
  const ContactListOut({
    required this.items,
  });
  
  factory ContactListOut.fromJson(Map<String, Object?> json) => _$ContactListOutFromJson(json);
  
  final List<ContactOut> items;

  Map<String, Object?> toJson() => _$ContactListOutToJson(this);
}
