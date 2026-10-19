// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'service_out.dart';

part 'service_list_out.g.dart';

@JsonSerializable()
class ServiceListOut {
  const ServiceListOut({
    required this.items,
  });
  
  factory ServiceListOut.fromJson(Map<String, Object?> json) => _$ServiceListOutFromJson(json);
  
  final List<ServiceOut> items;

  Map<String, Object?> toJson() => _$ServiceListOutToJson(this);
}
