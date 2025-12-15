// lib/core/services/location_service.dart
import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Service để quản lý tọa độ địa lý Việt Nam
class LocationService {
  // Tọa độ các tỉnh thành Việt Nam (ví dụ cho Tây Nguyên)
  static const Map<String, LatLng> vietnamProvinces = {
    // Tây Nguyên
    'Gia Lai': LatLng(13.9833, 108.0000),
    'Đắk Lắk': LatLng(12.6667, 108.0500),
    'Kon Tum': LatLng(14.3667, 107.9833),
    'Bình Định': LatLng(13.7778, 109.2333),
    'Quảng Ngãi': LatLng(15.1203, 108.7997),
    'Đà Nẵng': LatLng(16.0544, 108.2022),
    
    // Miền Bắc
    'Hà Nội': LatLng(21.0285, 105.8542),
    'Hải Phòng': LatLng(20.8449, 106.6881),
    'Hà Giang': LatLng(22.8038, 104.7772),
    
    // Miền Trung
    'Huế': LatLng(16.4637, 107.5909),
    'Nha Trang': LatLng(12.2383, 109.1967),
    
    // Miền Nam
    'Hồ Chí Minh': LatLng(10.7769, 106.6955),
    'Cần Thơ': LatLng(10.0341, 105.7857),
  };

  /// Lấy tọa độ của tỉnh thành
  static LatLng getCoordinates(String province) {
    return vietnamProvinces[province] ?? const LatLng(13.9833, 108.0000);
  }

  /// Tính khoảng cách giữa 2 điểm (km) - Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Bán kính Trái Đất (km)
    final dLat = _toRad(point2.latitude - point1.latitude);
    final dLon = _toRad(point2.longitude - point1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(point1.latitude)) * cos(_toRad(point2.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * (pi / 180);
}
