// lib/core/services/user_management_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'verification_service.dart';
import 'wallet_service.dart';
import '../../features/auth/services/auth_service.dart';

class UserManagementService {
  final _verificationService = VerificationService();

  // Get all users by scanning SharedPreferences and AuthService fake users
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Find all registered users (users who have completed registration)
      final userPhones = <String>{};
      
      // 1. Scan SharedPreferences for users who have logged in
      for (final key in keys) {
        if (key == 'user_phone') {
          final phone = prefs.getString(key);
          if (phone != null && phone.isNotEmpty) {
            userPhones.add(phone);
          }
        }
        // Also check for user_name_<phone> pattern
        if (key.startsWith('user_name_')) {
          final phone = key.replaceFirst('user_name_', '');
          if (phone.isNotEmpty) {
            userPhones.add(phone);
          }
        }
      }

      // 2. Add all fake users from AuthService (test users)
      final authService = AuthService.instance;
      for (final phone in authService.fakeUsers.keys) {
        userPhones.add(phone);
      }

      // 3. Build user profiles
      final users = <UserProfile>[];
      for (final phone in userPhones) {
        final user = await getUserById(phone);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID (phone number)
  Future<UserProfile?> getUserById(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService.instance;
      
      // Try to get from SharedPreferences first (user-specific keys only)
      String? name = prefs.getString('user_name_$userId');
      String? role = prefs.getString('user_role_$userId');
      
      // If not in SharedPreferences, check fake users
      if (authService.fakeUsers.containsKey(userId)) {
        final fakeUser = authService.fakeUsers[userId]!;
        name ??= fakeUser['name'] as String?;
        role ??= fakeUser['role'] as String?;
      }
      
      // Default role for users without role
      final userType = role ?? 'unknown';

      // Check if active
      final isActive = prefs.getBool('user_active_$userId') ?? true;

      // Check verification status
      final isVerified = await _verificationService.isUserVerified(userId, userType);

      // Get wallet balance
      final balance = await WalletService.getBalance(userId);

      // Get role-specific data
      String? vehicleType;
      String? licensePlate;
      String? idNumber;
      bool? hasRoute;
      String? address;
      String? company;

      if (userType == 'driver') {
        // Load from user-specific keys ONLY (not from global session keys)
        // This prevents data bleeding between different users
        vehicleType = prefs.getString('vehicle_type_$userId');
        licensePlate = prefs.getString('license_plate_$userId');
        idNumber = prefs.getString('id_number_$userId');
        hasRoute = prefs.getBool('driver_has_route_$userId'); // Check user-specific key only (preserved from logout)
      } else if (userType == 'shipper') {
        // Load from user-specific keys ONLY
        address = prefs.getString('address_$userId');
        company = prefs.getString('company_$userId');
      }

      // TODO: Get order count and rating from order/rating services
      final totalOrders = 0;
      final averageRating = null;

      return UserProfile(
        userId: userId,
        name: name ?? 'N/A',
        userType: userType,
        isActive: isActive,
        isVerified: isVerified,
        vehicleType: vehicleType,
        licensePlate: licensePlate,
        idNumber: idNumber,
        hasRoute: hasRoute,
        address: address,
        company: company,
        walletBalance: balance,
        totalOrders: totalOrders,
        averageRating: averageRating,
      );
    } catch (e) {
      print('Error getting user $userId: $e');
      return null;
    }
  }

  // Get users by type
  Future<List<UserProfile>> getUsersByType(String userType) async {
    final allUsers = await getAllUsers();
    return allUsers.where((user) => user.userType == userType).toList();
  }

  // Search users
  Future<List<UserProfile>> searchUsers(String query) async {
    final allUsers = await getAllUsers();
    final lowerQuery = query.toLowerCase();
    
    return allUsers.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
             user.userId.contains(query);
    }).toList();
  }

  // Update user info
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update name
      if (updates.containsKey('name')) {
        await prefs.setString('user_name_$userId', updates['name'] as String);
      }

      // Update driver-specific fields
      if (updates.containsKey('vehicleType')) {
        await prefs.setString('vehicle_type_$userId', updates['vehicleType'] as String);
      }
      if (updates.containsKey('licensePlate')) {
        await prefs.setString('license_plate_$userId', updates['licensePlate'] as String);
      }
      if (updates.containsKey('idNumber')) {
        await prefs.setString('id_number_$userId', updates['idNumber'] as String);
      }

      // Update shipper-specific fields
      if (updates.containsKey('address')) {
        await prefs.setString('address_$userId', updates['address'] as String);
      }
      if (updates.containsKey('company')) {
        await prefs.setString('company_$userId', updates['company'] as String);
      }

      // Update wallet balance if specified (using topUp for increase, withdraw for decrease)
      if (updates.containsKey('walletBalance')) {
        final newBalance = updates['walletBalance'] as double;
        final currentBalance = await WalletService.getBalance(userId);
        
        if (newBalance > currentBalance) {
          // Increase balance
          final diff = newBalance - currentBalance;
          await WalletService.topUp(userId, diff);
        } else if (newBalance < currentBalance) {
          // Decrease balance  
          final diff = currentBalance - newBalance;
          await WalletService.withdraw(userId, diff);
        }
      }

      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_active_$userId', isActive);
      return true;
    } catch (e) {
      print('Error toggling user status: $e');
      return false;
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final allUsers = await getAllUsers();
      final drivers = allUsers.where((u) => u.userType == 'driver').toList();
      final shippers = allUsers.where((u) => u.userType == 'shipper').toList();
      final verified = allUsers.where((u) => u.isVerified).toList();
      final active = allUsers.where((u) => u.isActive).toList();

      return {
        'totalUsers': allUsers.length,
        'totalDrivers': drivers.length,
        'totalShippers': shippers.length,
        'verifiedUsers': verified.length,
        'activeUsers': active.length,
        'verificationRate': allUsers.isEmpty ? 0.0 : (verified.length / allUsers.length) * 100,
      };
    } catch (e) {
      print('Error getting system stats: $e');
      return {
        'totalUsers': 0,
        'totalDrivers': 0,
        'totalShippers': 0,
        'verifiedUsers': 0,
        'activeUsers': 0,
        'verificationRate': 0.0,
      };
    }
  }
}
