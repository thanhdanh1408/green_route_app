// lib/features/auth/services/auth_service.dart
import 'package:flutter/material.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // CHỈ DÙNG SỐ ĐIỆN THOẠI LÀM KEY
  final Map<String, Map<String, dynamic>> fakeUsers = {
    // Tài xế
    '0987654321': {
      'password': '12345678',
      'role': 'driver',
      'name': 'Tài xế Nguyễn Văn Nam',
      'bank': 'Techcombank',
      'email':'nam123@gmail.com',
      'accountNumber': '190378291234',
      'accountName': 'NGUYEN VAN NAM',
    },
    // Chủ hàng
    '0977123456': {
      'password': '12345678',
      'role': 'shipper',
      'name': 'Chủ hàng Trần Thị Lan',
      'bank': 'Vietcombank',
      'accountNumber': '0011001934567',
      'accountName': 'TRAN THI LAN',
    },
    // Admin
    'admin': {
      'password': 'admin123',
      'role': 'admin',
      'name': 'Quản trị viên',
      'bank': 'MBBank',
      'accountNumber': '888888888888',
      'accountName': 'QUAN TRI VIEN',
    },
  };

  String? _lastSentPhone;
  String? _lastOtp = '123456';

  // Gửi OTP
  Future<bool> sendOtp(String input) async {
    await Future.delayed(const Duration(seconds: 2));
    final phone = _normalizePhone(input);
    if (fakeUsers.containsKey(phone) || fakeUsers.containsKey(input)) {
      _lastSentPhone = phone ?? input;
      debugPrint('OTP: 123456 gửi đến $_lastSentPhone');
      return true;
    }
    return false;
  }

  // Xác minh OTP
  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return otp == '123456';
  }

  // Đặt lại mật khẩu
  Future<bool> resetPassword(String newPass) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_lastSentPhone != null && fakeUsers.containsKey(_lastSentPhone!)) {
      fakeUsers[_lastSentPhone!]!['password'] = newPass;
      return true;
    }
    return false;
  }

  // ĐĂNG NHẬP – CHỈ DÙNG SỐ ĐIỆN THOẠI HOẶC "admin"
  Future<Map<String, dynamic>?> login(
    String identifier,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final input = identifier.trim();
    final phone = _normalizePhone(input);

    // Trường hợp nhập "admin"
    if (input == 'admin' && fakeUsers['admin']!['password'] == password) {
      debugPrint('Đăng nhập thành công: Admin');
      return fakeUsers['admin'];
    }

    // Trường hợp nhập số điện thoại
    if (phone != null &&
        fakeUsers.containsKey(phone) &&
        fakeUsers[phone]!['password'] == password) {
      debugPrint('Đăng nhập thành công: ${fakeUsers[phone]!['name']}');
      return fakeUsers[phone];
    }

    debugPrint('Đăng nhập thất bại: $input');
    return null;
  }

  // Helper: chuẩn hóa số điện thoại về dạng 0...
  String? _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    if (digits.startsWith('84')) {
      return '0${digits.substring(2)}';
    } else if (digits.startsWith('+84')) {
      return '0${digits.substring(3)}';
    } else if (digits.startsWith('0')) {
      return digits;
    }
    return null;
  }
}
