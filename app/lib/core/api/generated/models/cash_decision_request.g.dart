// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_decision_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashDecisionRequest _$CashDecisionRequestFromJson(Map<String, dynamic> json) =>
    CashDecisionRequest(
      paid: json['paid'] as bool? ?? true,
    );

Map<String, dynamic> _$CashDecisionRequestToJson(
        CashDecisionRequest instance) =>
    <String, dynamic>{
      'paid': instance.paid,
    };
