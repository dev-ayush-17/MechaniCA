// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'service_area_out.dart';

part 'mechanic_out.g.dart';

@JsonSerializable()
class MechanicOut {
  const MechanicOut({
    required this.displayName,
    required this.id,
    required this.languages,
    required this.lastHeartbeatAt,
    required this.online,
    required this.photoPath,
    required this.ratingAvg,
    required this.ratingCount,
    required this.serviceArea,
    required this.verificationStatus,
    required this.verified,
    required this.version,
    required this.yearsExperience,
    this.rejectionReason,
  });
  
  factory MechanicOut.fromJson(Map<String, Object?> json) => _$MechanicOutFromJson(json);
  
  final String displayName;
  final String id;
  final List<String> languages;
  final DateTime? lastHeartbeatAt;
  final bool online;
  final String photoPath;
  final num ratingAvg;
  final int ratingCount;
  final String? rejectionReason;
  final ServiceAreaOut? serviceArea;
  final String verificationStatus;
  final bool verified;
  final int version;
  final int yearsExperience;

  Map<String, Object?> toJson() => _$MechanicOutToJson(this);
}
