// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mechanic_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MechanicOut _$MechanicOutFromJson(Map<String, dynamic> json) => MechanicOut(
      displayName: json['displayName'] as String,
      id: json['id'] as String,
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      lastHeartbeatAt: json['lastHeartbeatAt'] == null
          ? null
          : DateTime.parse(json['lastHeartbeatAt'] as String),
      online: json['online'] as bool,
      photoPath: json['photoPath'] as String,
      ratingAvg: json['ratingAvg'] as num,
      ratingCount: (json['ratingCount'] as num).toInt(),
      serviceArea: json['serviceArea'] == null
          ? null
          : ServiceAreaOut.fromJson(
              json['serviceArea'] as Map<String, dynamic>),
      verificationStatus: json['verificationStatus'] as String,
      verified: json['verified'] as bool,
      version: (json['version'] as num).toInt(),
      yearsExperience: (json['yearsExperience'] as num).toInt(),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$MechanicOutToJson(MechanicOut instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'id': instance.id,
      'languages': instance.languages,
      'lastHeartbeatAt': instance.lastHeartbeatAt?.toIso8601String(),
      'online': instance.online,
      'photoPath': instance.photoPath,
      'ratingAvg': instance.ratingAvg,
      'ratingCount': instance.ratingCount,
      'rejectionReason': instance.rejectionReason,
      'serviceArea': instance.serviceArea,
      'verificationStatus': instance.verificationStatus,
      'verified': instance.verified,
      'version': instance.version,
      'yearsExperience': instance.yearsExperience,
    };
