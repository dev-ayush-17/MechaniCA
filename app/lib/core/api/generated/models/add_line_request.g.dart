// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_line_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddLineRequest _$AddLineRequestFromJson(Map<String, dynamic> json) =>
    AddLineRequest(
      amountPaise: (json['amountPaise'] as num).toInt(),
      name: json['name'] as String,
      kind: json['kind'] == null
          ? LineKind.valuePart
          : LineKind.fromJson(json['kind'] as String),
    );

Map<String, dynamic> _$AddLineRequestToJson(AddLineRequest instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'kind': _$LineKindEnumMap[instance.kind]!,
      'name': instance.name,
    };

const _$LineKindEnumMap = {
  LineKind.labor: 'labor',
  LineKind.valuePart: 'part',
  LineKind.fee: 'fee',
  LineKind.$unknown: r'$unknown',
};
