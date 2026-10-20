// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeOut _$DisputeOutFromJson(Map<String, dynamic> json) => DisputeOut(
      bookingId: json['bookingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerId: json['customerId'] as String,
      id: json['id'] as String,
      notes: (json['notes'] as List<dynamic>)
          .map((e) => DisputeNoteOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      reason: json['reason'] as String,
      resolution: json['resolution'] as String?,
      resolutionAmountPaise: (json['resolutionAmountPaise'] as num).toInt(),
      resolutionNote: json['resolutionNote'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$DisputeOutToJson(DisputeOut instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'createdAt': instance.createdAt.toIso8601String(),
      'customerId': instance.customerId,
      'id': instance.id,
      'notes': instance.notes,
      'reason': instance.reason,
      'resolution': instance.resolution,
      'resolutionAmountPaise': instance.resolutionAmountPaise,
      'resolutionNote': instance.resolutionNote,
      'status': instance.status,
    };
