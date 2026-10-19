// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bootstrap_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BootstrapRequest _$BootstrapRequestFromJson(Map<String, dynamic> json) =>
    BootstrapRequest(
      intent: Intent.fromJson(json['intent'] as String),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$BootstrapRequestToJson(BootstrapRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'intent': _$IntentEnumMap[instance.intent]!,
    };

const _$IntentEnumMap = {
  Intent.customer: 'customer',
  Intent.mechanic: 'mechanic',
  Intent.$unknown: r'$unknown',
};
