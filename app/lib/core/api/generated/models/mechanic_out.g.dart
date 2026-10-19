// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mechanic_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MechanicOut _$MechanicOutFromJson(Map<String, dynamic> json) => MechanicOut(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      photoPath: json['photoPath'] as String,
      yearsExperience: (json['yearsExperience'] as num).toInt(),
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      serviceArea: json['serviceArea'] == null
          ? null
          : ServiceAreaOut.fromJson(
              json['serviceArea'] as Map<String, dynamic>),
      verified: json['verified'] as bool,
      verificationStatus: json['verificationStatus'] as String,
      online: json['online'] as bool,
      lastHeartbeatAt: json['lastHeartbeatAt'] == null
          ? null
          : DateTime.parse(json['lastHeartbeatAt'] as String),
      ratingAvg: json['ratingAvg'] as num,
      ratingCount: (json['ratingCount'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$MechanicOutToJson(MechanicOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'photoPath': instance.photoPath,
      'yearsExperience': instance.yearsExperience,
      'languages': instance.languages,
      'serviceArea': instance.serviceArea,
      'verified': instance.verified,
      'verificationStatus': instance.verificationStatus,
      'online': instance.online,
      'lastHeartbeatAt': instance.lastHeartbeatAt?.toIso8601String(),
      'ratingAvg': instance.ratingAvg,
      'ratingCount': instance.ratingCount,
      'version': instance.version,
      'rejectionReason': instance.rejectionReason,
    };
