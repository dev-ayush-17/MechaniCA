import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/address_api.dart';
import '../domain/saved_address.dart';

class AddressesState {
  const AddressesState({this.items = const [], this.error});

  final List<SavedAddress> items;
  final String? error;
}

class AddressesController extends StateNotifier<AddressesState> {
  AddressesController(this._api) : super(const AddressesState());

  final AddressApi _api;

  Future<void> load() async {
    final result = await _api.list();
    state = result.when(
      onOk: (items) => AddressesState(items: items),
      onErr: (failure) => AddressesState(items: state.items, error: failure.message),
    );
  }

  Future<String?> add({
    required String label,
    required String line1,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    String? landmark,
  }) async {
    final result = await _api.create(
      label: label,
      line1: line1,
      city: city,
      pincode: pincode,
      lat: lat,
      lng: lng,
      landmark: landmark,
    );
    switch (result) {
      case Ok():
        await load();
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }

  Future<void> remove(String id) async {
    await _api.delete(id);
    await load();
  }
}
