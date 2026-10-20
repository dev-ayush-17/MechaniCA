// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offer_out.g.dart';

@JsonSerializable()
class OfferOut {
  const OfferOut({
    required this.attempt,
    required this.bookingId,
    required this.distanceKm,
    required this.expiresAt,
    required this.id,
    required this.mechanicId,
    required this.score,
    required this.serviceName,
    required this.status,
    required this.totalPaise,
    this.vehicleType = '',
  });
  
  factory OfferOut.fromJson(Map<String, Object?> json) => _$OfferOutFromJson(json);
  
  final int attempt;
  final String bookingId;
  final num distanceKm;
  final DateTime expiresAt;
  final String id;
  final String mechanicId;
  final num score;
  final String serviceName;
  final String status;
  final int totalPaise;
  final String vehicleType;

  Map<String, Object?> toJson() => _$OfferOutToJson(this);
}
