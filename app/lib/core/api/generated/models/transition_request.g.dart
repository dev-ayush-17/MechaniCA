// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transition_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransitionRequest _$TransitionRequestFromJson(Map<String, dynamic> json) =>
    TransitionRequest(
      to: BookingStatus.fromJson(json['to'] as String),
      expectedVersion: (json['expectedVersion'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TransitionRequestToJson(TransitionRequest instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'to': _$BookingStatusEnumMap[instance.to]!,
    };

const _$BookingStatusEnumMap = {
  BookingStatus.requested: 'requested',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.mechanicAssigned: 'mechanicAssigned',
  BookingStatus.enRoute: 'enRoute',
  BookingStatus.arrived: 'arrived',
  BookingStatus.inService: 'inService',
  BookingStatus.completed: 'completed',
  BookingStatus.paid: 'paid',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.failed: 'failed',
  BookingStatus.disputed: 'disputed',
  BookingStatus.$unknown: r'$unknown',
};
