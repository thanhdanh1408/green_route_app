// lib/core/models/user_profile.dart
class UserProfile {
  final String userId; // phone number
  final String name;
  final String userType; // 'driver' or 'shipper'
  final bool isActive;
  final bool isVerified;
  final DateTime? registeredAt;
  
  // Driver specific
  final String? vehicleType;
  final String? licensePlate;
  final String? idNumber;
  final bool? hasRoute;
  
  // Shipper specific
  final String? address;
  final String? company;
  
  // Stats
  final double walletBalance;
  final int totalOrders;
  final double? averageRating;

  UserProfile({
    required this.userId,
    required this.name,
    required this.userType,
    this.isActive = true,
    this.isVerified = false,
    this.registeredAt,
    this.vehicleType,
    this.licensePlate,
    this.idNumber,
    this.hasRoute,
    this.address,
    this.company,
    this.walletBalance = 0.0,
    this.totalOrders = 0,
    this.averageRating,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'userType': userType,
      'isActive': isActive,
      'isVerified': isVerified,
      'registeredAt': registeredAt?.toIso8601String(),
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
      'idNumber': idNumber,
      'hasRoute': hasRoute,
      'address': address,
      'company': company,
      'walletBalance': walletBalance,
      'totalOrders': totalOrders,
      'averageRating': averageRating,
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'] as String)
          : null,
      vehicleType: json['vehicleType'] as String?,
      licensePlate: json['licensePlate'] as String?,
      idNumber: json['idNumber'] as String?,
      hasRoute: json['hasRoute'] as bool?,
      address: json['address'] as String?,
      company: json['company'] as String?,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }

  // Copy with
  UserProfile copyWith({
    String? userId,
    String? name,
    String? userType,
    bool? isActive,
    bool? isVerified,
    DateTime? registeredAt,
    String? vehicleType,
    String? licensePlate,
    String? idNumber,
    bool? hasRoute,
    String? address,
    String? company,
    double? walletBalance,
    int? totalOrders,
    double? averageRating,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      registeredAt: registeredAt ?? this.registeredAt,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      idNumber: idNumber ?? this.idNumber,
      hasRoute: hasRoute ?? this.hasRoute,
      address: address ?? this.address,
      company: company ?? this.company,
      walletBalance: walletBalance ?? this.walletBalance,
      totalOrders: totalOrders ?? this.totalOrders,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  // Get display name for user type
  String getUserTypeDisplay() {
    switch (userType) {
      case 'driver':
        return 'Tài xế';
      case 'shipper':
        return 'Chủ hàng';
      case 'admin':
        return 'Admin';
      case 'unknown':
        return 'Chưa chọn role';
      default:
        return userType;
    }
  }

  // Get status text
  String getStatusText() {
    return isActive ? 'Hoạt động' : 'Tạm khóa';
  }

  // Get verification status text
  String getVerificationText() {
    return isVerified ? 'Đã xác minh' : 'Chưa xác minh';
  }
}
