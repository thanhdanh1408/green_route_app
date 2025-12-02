// lib/features/auth/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final Map<String, Map<String, dynamic>> fakeUsers = {
    '0987654321': {
      'password': '12345678',
      'role': 'driver',
      'hasRole': true,
      'hasRoute': false,
      'name': 'Tài xế Nguyễn Văn Nam',
      'bank': 'Techcombank',
      'email': 'nam123@gmail.com',
      'accountNumber': '190378291234',
      'accountName': 'NGUYEN VAN NAM',
    },
    '0977123456': {
      'password': '12345678',
      'role': 'shipper',
      'hasRole': true,
      'name': 'Chủ hàng Trần Thị Lan',
      'bank': 'Vietcombank',
      'email': 'lan321@gmail.com',
      'accountNumber': '0011001934567',
      'accountName': 'TRAN THI LAN',
    },
    '0901234567': {
      'password': '12345678',
      'role': null,
      'hasRole': false,
      'hasRoute': false,
      'name': 'Người dùng mới',
    },
    'admin': {
      'password': 'admin123',
      'role': 'admin',
      'hasRole': true,
      'name': 'Quản trị viên',
      'bank': 'MBBank',
      'accountNumber': '888888888888',
      'accountName': 'QUAN TRI VIEN',
    },
  };

  String? _lastSentPhone;

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

  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return otp == '123456';
  }

  Future<bool> resetPassword(String newPass) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_lastSentPhone != null && fakeUsers.containsKey(_lastSentPhone!)) {
      fakeUsers[_lastSentPhone!]!['password'] = newPass;
      return true;
    }
    return false;
  }

  // ĐĂNG NHẬP
  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final input = identifier.trim();
    final phone = _normalizePhone(input);

    if (input == 'admin' && fakeUsers['admin']!['password'] == password) {
      return fakeUsers['admin'];
    }

    if (phone != null && fakeUsers.containsKey(phone) && fakeUsers[phone]!['password'] == password) {
      return fakeUsers[phone];
    }
    return null;
  }

  // CẬP NHẬT ROLE CHO NGƯỜI DÙNG MỚI
  Future<bool> updateRole(String phone, String role) async {
    final normalized = _normalizePhone(phone) ?? phone;
    if (fakeUsers.containsKey(normalized)) {
      fakeUsers[normalized]!['role'] = role;
      fakeUsers[normalized]!['hasRole'] = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setString('user_phone', normalized);

      debugPrint('Cập nhật role: $normalized → $role');
      return true;
    }
    return false;
  }

  String? _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    if (digits.startsWith('84')) return '0${digits.substring(2)}';
    if (digits.startsWith('+84')) return '0${digits.substring(3)}';
    if (digits.startsWith('0')) return digits;
    return null;
  }

  // ĐĂNG XUẤT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('id');
    await prefs.remove('plate');
    await prefs.remove('vehicle_type');
    await prefs.remove('capacity');
    await prefs.remove('area');
    await prefs.remove('bank');
    await prefs.remove('account');
    await prefs.remove('account_name');
    debugPrint('Đã đăng xuất và xóa dữ liệu người dùng');
  }
}
