import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_api.dart';

class HomeController extends StateNotifier<AsyncValue<List<Booking>>> {
  HomeController(this._api) : super(const AsyncLoading());

  final BookingApi _api;

  Future<void> load() async {
    if (!state.hasValue) {
      state = const AsyncLoading();
    }
    final result = await _api.listMine();
    state = result.when(
      onOk: AsyncData.new,
      onErr: (failure) => AsyncError(failure.message, StackTrace.current),
    );
  }
}
