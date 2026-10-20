import '../../../core/error/result.dart';
import 'emergency_contact.dart';

abstract class ContactApi {
  Future<Result<List<EmergencyContact>>> list();

  Future<Result<EmergencyContact>> create({
    required String name,
    required String phone,
  });

  Future<Result<void>> delete(String contactId);
}
