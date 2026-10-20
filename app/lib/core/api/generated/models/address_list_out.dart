// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_out.dart';

part 'address_list_out.g.dart';

@JsonSerializable()
class AddressListOut {
  const AddressListOut({
    required this.items,
  });
  
  factory AddressListOut.fromJson(Map<String, Object?> json) => _$AddressListOutFromJson(json);
  
  final List<AddressOut> items;

  Map<String, Object?> toJson() => _$AddressListOutToJson(this);
}
