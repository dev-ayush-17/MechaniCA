// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'service_area_out.dart';

part 'mechanic_out.g.dart';

@JsonSerializable()
class MechanicOut {
  const MechanicOut({
    required this.id,
    required this.displayName,
    required this.photoPath,
    required this.yearsExperience,
    required this.languages,
    required this.serviceArea,
    required this.verified,
    required this.verificationStatus,
    required this.online,
    required this.lastHeartbeatAt,
    required this.ratingAvg,
    required this.ratingCount,
    required this.version,
    this.rejectionReason,
  });
  
  factory MechanicOut.fromJson(Map<String, Object?> json) => _$MechanicOutFromJson(json);
  
  final String id;
  final String displayName;
  final String photoPath;
  final int yearsExperience;
  final List<String> languages;
  final ServiceAreaOut? serviceArea;
  final bool verified;
  final String verificationStatus;
  final bool online;
  final DateTime? lastHeartbeatAt;
  final num ratingAvg;
  final int ratingCount;
  final int version;
  final String? rejectionReason;

  Map<String, Object?> toJson() => _$MechanicOutToJson(this);
}
