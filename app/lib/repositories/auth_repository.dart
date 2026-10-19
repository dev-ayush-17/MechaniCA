import '../models/user_model.dart';
import '../mock/mock_data.dart';
import '../mock/mock_delay.dart';

abstract class AuthRepository {
  Future<UserModel> loginWithPhone(String phone, String otp);
  Future<void> sendOtp(String phone);
  Future<UserModel> loginWithGoogle();
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> forgotPassword(String phone);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {
    await MockDelay.wait();
    // Mock: always succeeds
  }

  @override
  Future<UserModel> loginWithPhone(String phone, String otp) async {
    await MockDelay.wait();
    if (otp == '123456' || otp.length == 6) {
      return mockUser;
    }
    throw Exception('Invalid OTP');
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await MockDelay.wait();
    return mockUser;
  }

  @override
  Future<void> logout() async {
    await MockDelay.short();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await MockDelay.short();
    return mockUser;
  }

  @override
  Future<void> forgotPassword(String phone) async {
    await MockDelay.wait();
  }
}
