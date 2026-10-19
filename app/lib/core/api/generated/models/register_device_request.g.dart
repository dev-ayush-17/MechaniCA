// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDeviceRequest _$RegisterDeviceRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterDeviceRequest(
      platform: json['platform'] as String,
      token: json['token'] as String,
    );

Map<String, dynamic> _$RegisterDeviceRequestToJson(
        RegisterDeviceRequest instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'token': instance.token,
    };
