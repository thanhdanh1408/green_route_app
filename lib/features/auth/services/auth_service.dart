// lib/features/auth/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final Map<String, Map<String, dynamic>> fakeUsers = {
    'admin': {
      'password': 'admin123',
      'role': 'admin',
      'hasRole': true,
      'name': 'Quản trị viên',
      'bank': 'MBBank',
      'accountNumber': '888888888888',
      'accountName': 'QUAN TRI VIEN',
    },
    '0987654321': {
      'password': '12345678',
      'role': 'driver',
      'hasRole': true,
      'hasRoute': true,
      'name': 'Nguyễn Văn Nam',
      'address': 'Gia Lai',
      'vehicleType': 'Xe tải nặng',
      'licensePlate': '77A-8977',
      'idNumber': '123456789012',
      'bank': 'Techcombank',
      'accountNumber': '190378291234',
      'accountName': 'NGUYEN VAN NAM',
      'idStatus': 'approved',
      'licenseStatus': 'approved',
    },
    '0978123456': {
      'password': '12345678',
      'role': 'driver',
      'hasRole': true,
      'hasRoute': true,
      'name': 'Phạm Văn Tuấn',
      'address': 'Gia Lai',
      'vehicleType': 'Xe tải trung',
      'licensePlate': '30A-12345',
      'idNumber': '987654321098',
      'bank': 'Techcombank',
      'accountNumber': '190378291234',
      'accountName': 'PHAM VAN TUAN',
      'idStatus': 'approved',
      'licenseStatus': 'approved',
    },
    '0977123456': {
      'password': '12345678',
      'role': 'shipper',
      'hasRole': true,
      'name': 'Trần Thị Lan',
      'address': 'Quảng Ngãi',
      'company': 'Công ty TNHH Vận tải Lan',
      'bank': 'Vietcombank',
      'accountNumber': '0011001934567',
      'accountName': 'TRAN THI LAN',
      'idStatus': 'approved',
    },
    '0981521407': {
      'password': '12345678',
      'role': 'shipper',
      'hasRole': true,
      'name': 'Phan Thành Danh',
      'address': 'Quy Nhơn',
      'company': 'Công ty CP Vận tải Bình Định',
      'bank': 'Vietcombank',
      'accountNumber': '0011001934567',
      'accountName': 'PHAN THANH DANH',
      'idStatus': 'approved',
    },
    '0901234567': {
      'password': '12345678',
      'role': null,
      'hasRole': false,
      'hasRoute': false,
      'name': 'Người dùng mới',
      'idStatus': 'pending',
    },
    '0797316607': {
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

  // GỬI OTP CHO ĐĂNG KÝ
  Future<String?> sendOtpForRegister(String input) async {
    await Future.delayed(const Duration(seconds: 2));
    final phone = _normalizePhone(input);
    
    if (phone == null) {
      return 'Số điện thoại không hợp lệ';
    }
    
    if (fakeUsers.containsKey(phone)) {
      return 'Số điện thoại đã được đăng ký';
    }
    
    _lastSentPhone = phone;
    debugPrint('OTP: 123456 gửi đến $_lastSentPhone');
    return null; // null = thành công
  }

  // GỬI OTP CHO QUÊN MẬT KHẨU
  Future<String?> sendOtpForForgotPassword(String input) async {
    await Future.delayed(const Duration(seconds: 2));
    final phone = _normalizePhone(input);
    
    if (phone == null) {
      return 'Số điện thoại không hợp lệ';
    }
    
    if (!fakeUsers.containsKey(phone)) {
      return 'Tài khoản không tồn tại';
    }
    
    _lastSentPhone = phone;
    debugPrint('OTP: 123456 gửi đến $_lastSentPhone');
    return null;
  }

  // XÁC NHẬN OTP
  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return otp == '123456';
  }

  // ĐĂNG KÝ TÀI KHOẢN MỚI
  Future<bool> registerNewUser(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final normalized = _normalizePhone(phone) ?? phone;
    
    debugPrint('registerNewUser: phone=$phone, normalized=$normalized, lastSentPhone=$_lastSentPhone');
    
    // Nếu _lastSentPhone không khớp, có thể là do người dùng làm lại flow
    // Trong trường hợp này, ta vẫn cho phép đăng ký nếu số điện thoại chưa tồn tại
    if (_lastSentPhone != normalized && fakeUsers.containsKey(normalized)) {
      debugPrint('registerNewUser failed: Account already exists');
      return false;
    }
    
    // Tạo user mới
    fakeUsers[normalized] = {
      'password': password,
      'role': null,
      'hasRole': false,
      'name': 'Người dùng mới',
      'address': '',
      'bank': '',
      'accountNumber': '',
      'accountName': '',
      'idStatus': 'pending',
    };
    
    debugPrint('Đã tạo tài khoản mới: $normalized với password: $password');
    debugPrint('Current fakeUsers: ${fakeUsers.keys.toList()}');
    return true;
  }

  // CẬP NHẬT THÔNG TIN ROLE (DRIVER/SHIPPER)
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

  // ĐẶT LẠI MẬT KHẨU
  Future<bool> resetPassword(String newPassword) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_lastSentPhone != null && fakeUsers.containsKey(_lastSentPhone!)) {
      fakeUsers[_lastSentPhone!]!['password'] = newPassword;
      debugPrint('Đã đặt lại mật khẩu cho: $_lastSentPhone');
      return true;
    }
    return false;
  }

  // ĐỔI MẬT KHẨU
  Future<String?> changePassword(String phone, String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalized = _normalizePhone(phone) ?? phone;
    
    if (!fakeUsers.containsKey(normalized)) {
      return 'Tài khoản không tồn tại';
    }
    
    if (fakeUsers[normalized]!['password'] != oldPassword) {
      return 'Mật khẩu cũ không chính xác';
    }
    
    fakeUsers[normalized]!['password'] = newPassword;
    debugPrint('Đã đổi mật khẩu cho: $normalized');
    return null;
  }

  // ĐĂNG NHẬP
  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final input = identifier.trim();
    final phone = _normalizePhone(input);

    debugPrint('=== AUTH SERVICE LOGIN ===');
    debugPrint('Input identifier: $input');
    debugPrint('Normalized phone: $phone');
    debugPrint('Password: $password');
    debugPrint('Available users: ${fakeUsers.keys.toList()}');

    if (input == 'admin' && fakeUsers['admin']!['password'] == password) {
      debugPrint('✓ Admin login success');
      return fakeUsers['admin'];
    }

    if (phone != null) {
      debugPrint('Checking user: $phone');
      if (fakeUsers.containsKey(phone)) {
        final storedPassword = fakeUsers[phone]!['password'];
        debugPrint('User exists. Stored password: $storedPassword, Input password: $password');
        if (storedPassword == password) {
          debugPrint('✓ Login success');
          return fakeUsers[phone];
        } else {
          debugPrint('✗ Password mismatch');
        }
      } else {
        debugPrint('✗ User not found with phone: $phone');
      }
    }
    debugPrint('✗ Login failed for identifier: $identifier');
    return null;
  }

  // CHUẨN HÓA SỐ ĐIỆN THOẠI
  String? _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    if (digits.length == 10 && digits.startsWith('0')) return digits; // Sửa lỗi ở đây
    if (digits.startsWith('84')) return '0${digits.substring(2)}';
    if (digits.startsWith('+84')) return '0${digits.substring(3)}';
    return null;
  }

  // ĐĂNG XUẤT
  Future<void> logout() async {
    debugPrint('🚪 LOGOUT STARTED');
    final prefs = await SharedPreferences.getInstance();
    
    // 🔒 PRESERVE verification documents before clearing session data
    final verificationDocuments = prefs.getString('verification_documents');
    debugPrint('🔒 Saved documents before logout: ${verificationDocuments != null ? "YES (${verificationDocuments.length} chars)" : "NO"}');
    
    // 🔒 PRESERVE user-specific keys before clearing (for admin queries and next login)
    final currentUserId = prefs.getString('user_phone');
    Map<String, String> userSpecificStringKeys = {};
    Map<String, bool> userSpecificBoolKeys = {};
    
    if (currentUserId != null) {
      // Save all STRING keys that will be queried by admin
      final userName = prefs.getString('user_name_$currentUserId');
      final userRole = prefs.getString('user_role_$currentUserId');
      final vehicleTypeUser = prefs.getString('vehicle_type_$currentUserId');
      final licensePlateUser = prefs.getString('license_plate_$currentUserId');
      final idNumberUser = prefs.getString('id_number_$currentUserId');
      final driverRouteFromUser = prefs.getString('driver_route_from_$currentUserId');
      final driverRouteToUser = prefs.getString('driver_route_to_$currentUserId');
      final driverRouteWeightUser = prefs.getString('driver_route_weight_$currentUserId');
      final driverRouteTimeRangeUser = prefs.getString('driver_route_time_range_$currentUserId');
      final addressUser = prefs.getString('address_$currentUserId');
      final companyUser = prefs.getString('company_$currentUserId');
      
      if (userName != null) userSpecificStringKeys['user_name_$currentUserId'] = userName;
      if (userRole != null) userSpecificStringKeys['user_role_$currentUserId'] = userRole;
      if (vehicleTypeUser != null) userSpecificStringKeys['vehicle_type_$currentUserId'] = vehicleTypeUser;
      if (licensePlateUser != null) userSpecificStringKeys['license_plate_$currentUserId'] = licensePlateUser;
      if (idNumberUser != null) userSpecificStringKeys['id_number_$currentUserId'] = idNumberUser;
      if (driverRouteFromUser != null) userSpecificStringKeys['driver_route_from_$currentUserId'] = driverRouteFromUser;
      if (driverRouteToUser != null) userSpecificStringKeys['driver_route_to_$currentUserId'] = driverRouteToUser;
      if (driverRouteWeightUser != null) userSpecificStringKeys['driver_route_weight_$currentUserId'] = driverRouteWeightUser;
      if (driverRouteTimeRangeUser != null) userSpecificStringKeys['driver_route_time_range_$currentUserId'] = driverRouteTimeRangeUser;
      if (addressUser != null) userSpecificStringKeys['address_$currentUserId'] = addressUser;
      if (companyUser != null) userSpecificStringKeys['company_$currentUserId'] = companyUser;
      
      // 🔒 CRITICAL: Save BOOL keys (driver_has_route is a BOOL!)
      final driverHasRoute = prefs.getBool('driver_has_route_$currentUserId');
      if (driverHasRoute != null) userSpecificBoolKeys['driver_has_route_$currentUserId'] = driverHasRoute;
      
      debugPrint('🔒 Saved ${userSpecificStringKeys.length} string keys + ${userSpecificBoolKeys.length} bool keys before logout');
    }
    
    // ⚠️ Clear global session keys so next user doesn't see previous user's data
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('id');
    await prefs.remove('plate');
    await prefs.remove('vehicle_type');
    await prefs.remove('capacity');
    await prefs.remove('area');
    await prefs.remove('id_number');
    await prefs.remove('bank');
    await prefs.remove('account');
    await prefs.remove('account_name');
    await prefs.remove('temp_phone');
    await prefs.remove('temp_password');
    await prefs.remove('driver_has_route');
    await prefs.remove('driver_route_from');
    await prefs.remove('driver_route_to');
    await prefs.remove('driver_route_weight');
    await prefs.remove('driver_route_time_range');
    await prefs.remove('address');
    await prefs.remove('company');
    await prefs.remove('license_plate');
    
    // 🔒 RESTORE verification documents after clear
    if (verificationDocuments != null) {
      await prefs.setString('verification_documents', verificationDocuments);
      debugPrint('🔒 Verification documents RESTORED after logout');
    }
    
    // 🔒 RESTORE all user-specific STRING keys
    for (final entry in userSpecificStringKeys.entries) {
      await prefs.setString(entry.key, entry.value);
    }
    
    // 🔒 RESTORE all user-specific BOOL keys
    for (final entry in userSpecificBoolKeys.entries) {
      await prefs.setBool(entry.key, entry.value);
    }
    
    if (userSpecificStringKeys.isNotEmpty || userSpecificBoolKeys.isNotEmpty) {
      debugPrint('🔒 ${userSpecificStringKeys.length} string + ${userSpecificBoolKeys.length} bool keys RESTORED after logout');
    }
    
    // ⚠️ KHÔNG xóa empty_trips vì đây là dữ liệu GLOBAL (dùng chung cho tất cả users)
    debugPrint('🚪 LOGOUT COMPLETED');
  }

  // GET CURRENT USER ID (phone number)
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  // GET CURRENT USER ROLE
  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // GET CURRENT USER NAME
  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? prefs.getString('name');
  }

  // CHECK IF USER IS LOGGED IN
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    final role = prefs.getString('user_role');
    return phone != null && role != null;
  }

  // GET CURRENT USER FULL INFO
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final role = await getCurrentUserRole();
    final name = await getCurrentUserName();

    return {
      'userId': userId,
      'phone': userId,
      'role': role,
      'name': name ?? 'N/A',
      // Add more fields as needed
    };
  }

  // CLEAR ALL DATA (khi user yêu cầu reset)
  Future<void> clearAllOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bidding_orders');
    await prefs.remove('accepted_orders');
    await prefs.remove('waiting_orders');
    await prefs.remove('completed_orders');
    await prefs.remove('shipper_received_bids');
    debugPrint('Đã xóa tất cả dữ liệu đơn hàng');
  }
}
