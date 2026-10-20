import '../../../core/error/result.dart';
import '../domain/contact_api.dart';
import '../domain/emergency_contact.dart';

class FakeContactApi implements ContactApi {
  FakeContactApi([List<EmergencyContact>? seed]) : items = [...?seed];

  final List<EmergencyContact> items;

  @override
  Future<Result<List<EmergencyContact>>> list() async => Ok(List.of(items));

  @override
  Future<Result<EmergencyContact>> create({
    required String name,
    required String phone,
  }) async {
    if (items.length >= 3) {
      return const Err(InvalidInput('You can save up to 3 emergency contacts.'));
    }
    final contact = EmergencyContact(
      id: 'con_${items.length + 1}',
      name: name.trim(),
      phoneE164: phone.startsWith('+91') ? phone : '+91$phone',
    );
    items.add(contact);
    return Ok(contact);
  }

  @override
  Future<Result<void>> delete(String contactId) async {
    items.removeWhere((item) => item.id == contactId);
    return const Ok(null);
  }
}
