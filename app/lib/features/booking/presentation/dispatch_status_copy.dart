import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/booking_model.dart';

const kFindingMechanicCopy = 'Finding a mechanic near you';
const kStillLookingCopy = 'Still looking. The first mechanic was unavailable.';
const kDispatchFailedCopy =
    'No mechanic is free nearby. Try again or contact support.';
const kSosDispatchFailedCopy =
    'No mechanic could take the priority request. If this is an emergency, call 112.';

String dispatchStatusCopy({
  required BookingStatus status,
  int attempt = 1,
  bool sos = false,
}) {
  if (status == BookingStatus.failed) {
    return sos ? kSosDispatchFailedCopy : kDispatchFailedCopy;
  }
  if (status == BookingStatus.confirmed && attempt > 1) {
    return kStillLookingCopy;
  }
  return kFindingMechanicCopy;
}

class DispatchStatusCopy extends StatelessWidget {
  const DispatchStatusCopy({
    super.key,
    required this.status,
    this.attempt = 1,
    this.sos = false,
  });

  final BookingStatus status;
  final int attempt;
  final bool sos;

  @override
  Widget build(BuildContext context) {
    return Text(
      dispatchStatusCopy(status: status, attempt: attempt, sos: sos),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    );
  }
}
