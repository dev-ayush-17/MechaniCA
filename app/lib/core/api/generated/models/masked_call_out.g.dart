// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'masked_call_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaskedCallOut _$MaskedCallOutFromJson(Map<String, dynamic> json) =>
    MaskedCallOut(
      dialNumber: json['dialNumber'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$MaskedCallOutToJson(MaskedCallOut instance) =>
    <String, dynamic>{
      'dialNumber': instance.dialNumber,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
