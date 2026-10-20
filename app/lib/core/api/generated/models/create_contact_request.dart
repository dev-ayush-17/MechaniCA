// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_contact_request.g.dart';

@JsonSerializable()
class CreateContactRequest {
  const CreateContactRequest({
    required this.name,
    required this.phone,
  });
  
  factory CreateContactRequest.fromJson(Map<String, Object?> json) => _$CreateContactRequestFromJson(json);
  
  final String name;
  final String phone;

  Map<String, Object?> toJson() => _$CreateContactRequestToJson(this);
}
