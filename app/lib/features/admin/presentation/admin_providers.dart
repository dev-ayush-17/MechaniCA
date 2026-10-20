import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_admin_api.dart';
import '../domain/admin_api.dart';

/// Isolated admin composition. Do not import maps, camera, or RTDB here.
final adminRoleProvider = StateProvider<String>((ref) => 'admin');

final adminApiProvider = Provider<AdminApi>((ref) => FakeAdminApi());

bool canRefund(String role) => role == 'admin' || role == 'super_admin';
