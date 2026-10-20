import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/contact_api.dart';
import '../domain/emergency_contact.dart';

class ContactsState {
  const ContactsState({this.items = const [], this.error});

  final List<EmergencyContact> items;
  final String? error;
}

class ContactsController extends StateNotifier<ContactsState> {
  ContactsController(this._api) : super(const ContactsState());

  final ContactApi _api;

  Future<void> load() async {
    final result = await _api.list();
    state = result.when(
      onOk: (items) => ContactsState(items: items),
      onErr: (failure) => ContactsState(items: state.items, error: failure.message),
    );
  }

  Future<String?> add({required String name, required String phone}) async {
    final result = await _api.create(name: name, phone: phone);
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
