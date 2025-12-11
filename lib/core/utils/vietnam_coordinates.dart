// lib/core/utils/vietnam_coordinates.dart
import 'package:latlong2/latlong.dart';

class VietnamCoordinates {
  // Map of 11 Central Highlands provinces to coordinates
  static final Map<String, LatLng> provinceCoordinates = {
    // Miền Trung Tây Nguyên
    'Thành phố Huế': LatLng(16.4637, 107.5909),
    'Huế': LatLng(16.4637, 107.5909),
    
    'Thành phố Đà Nẵng': LatLng(16.0544, 108.2022),
    'Đà Nẵng': LatLng(16.0544, 108.2022),
    
    'Tỉnh Thanh Hóa': LatLng(19.8067, 105.7851),
    'Thanh Hóa': LatLng(19.8067, 105.7851),
    
    'Tỉnh Nghệ An': LatLng(19.3344, 104.9200),
    'Nghệ An': LatLng(19.3344, 104.9200),
    
    'Tỉnh Hà Tĩnh': LatLng(18.3559, 105.9068),
    'Hà Tĩnh': LatLng(18.3559, 105.9068),
    
    'Tỉnh Quảng Trị': LatLng(16.7943, 107.1851),
    'Quảng Trị': LatLng(16.7943, 107.1851),
    
    'Tỉnh Quảng Ngãi': LatLng(15.1214, 108.8044),
    'Quảng Ngãi': LatLng(15.1214, 108.8044),
    'Quy Nhơn': LatLng(13.7830, 109.2196), // Quy Nhơn city in Bình Định
    
    'Tỉnh Khánh Hòa': LatLng(12.2388, 109.1967),
    'Khánh Hòa': LatLng(12.2388, 109.1967),
    'Nha Trang': LatLng(12.2388, 109.1967),
    
    'Tỉnh Gia Lai': LatLng(13.9833, 108.0000),
    'Gia Lai': LatLng(13.9833, 108.0000),
    'Pleiku': LatLng(13.9833, 108.0000),
    
    'Tỉnh Đắk Lắk': LatLng(12.6667, 108.0500),
    'Đắk Lắk': LatLng(12.6667, 108.0500),
    'Buôn Ma Thuột': LatLng(12.6667, 108.0500),
    'Buôn Mê Thuột': LatLng(12.6667, 108.0500),
    
    'Tỉnh Lâm Đồng': LatLng(11.9404, 108.4583),
    'Lâm Đồng': LatLng(11.9404, 108.4583),
    'Đà Lạt': LatLng(11.9404, 108.4583),
  };

  /// Get coordinates from province/city name
  /// Returns null if not found
  static LatLng? getCoordinates(String provinceName) {
    // Try exact match first
    if (provinceCoordinates.containsKey(provinceName)) {
      return provinceCoordinates[provinceName];
    }
    
    // Try case-insensitive match
    final lowerName = provinceName.toLowerCase();
    for (var entry in provinceCoordinates.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    
    // Try partial match (contains)
    for (var entry in provinceCoordinates.entries) {
      if (entry.key.toLowerCase().contains(lowerName) || 
          lowerName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    return null; // Not found
  }

  /// Get coordinates with fallback to default
  static LatLng getCoordinatesOrDefault(String provinceName, {LatLng? defaultCoord}) {
    return getCoordinates(provinceName) ?? 
           defaultCoord ?? 
           LatLng(13.9833, 108.0000); // Default: Pleiku
  }
}
