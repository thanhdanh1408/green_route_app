// lib/core/services/vietnam_locations_service.dart
import 'package:latlong2/latlong.dart';

/// Comprehensive Vietnam location database with province → district → ward mapping
/// Contains coordinates for major locations to display on map
class VietnamLocationsService {
  
  // ============================================================
  // MAJOR CITIES & PROVINCES WITH COORDINATES (For Map Display)
  // ============================================================
  static const Map<String, LatLng> provinceCapitals = {
    // Miền Trung - Tây Nguyên (11 tỉnh/TP)
    'Thanh Hóa': LatLng(19.8075, 105.7797),          // 1. Thanh Hóa
    'Nghệ An': LatLng(18.6867, 105.6872),            // 2. Nghệ An
    'Hà Tĩnh': LatLng(18.3431, 105.8953),            // 3. Hà Tĩnh
    'Quảng Trị': LatLng(16.7500, 107.1917),          // 4. Quảng Trị (+ Quảng Bình)
    'Thừa Thiên Huế': LatLng(16.4637, 107.5909),     // 5. Thừa Thiên Huế
    'Thành phố Đà Nẵng': LatLng(16.0544, 108.2022),  // 6. Đà Nẵng (+ Quảng Nam)
    'Quảng Ngãi': LatLng(15.1203, 108.7997),         // 7. Quảng Ngãi (+ Kon Tum)
    'Gia Lai': LatLng(14.1588, 108.7817),            // 8. Gia Lai (+ Bình Định) - Bình Định center
    'Đắk Lắk': LatLng(12.6667, 108.0500),            // 9. Đắk Lắk (+ Phú Yên)
    'Khánh Hòa': LatLng(12.2383, 109.1967),          // 10. Khánh Hòa (+ Ninh Thuận)
    'Lâm Đồng': LatLng(11.9400, 108.4400),           // 11. Lâm Đồng (+ Đắk Nông + Bình Thuận)
  };

  // ============================================================
  // DISTRICTS & MAJOR WARDS WITH DETAILED COORDINATES
  // ============================================================
  static const Map<String, Map<String, LatLng>> provincesWithDistricts = {
    // 1. THANH HÓA
    'Thanh Hóa': {
      'Thanh Hóa': LatLng(19.8075, 105.7797),       // Center
      'Sầm Sơn': LatLng(19.7333, 105.8667),         // East (Beach)
      'Hoằng Hóa': LatLng(20.0500, 105.7500),       // North
      'Thiệu Hóa': LatLng(20.0333, 105.5833),       // Northwest
      'Bình Lương': LatLng(19.5667, 105.5333),      // West
    },
    
    // 2. NGHỆ AN
    'Nghệ An': {
      'Vinh': LatLng(18.6867, 105.6872),            // Center
      'Cửa Lò': LatLng(18.7333, 105.7333),          // East (Beach)
      'Hoàng Mai': LatLng(18.9000, 105.7333),       // North
      'Tân Kỳ': LatLng(18.8333, 105.2667),          // Northwest
      'Quỳ Châu': LatLng(18.5333, 104.9000),        // West
    },
    
    // 3. HÀ TĨNH
    'Hà Tĩnh': {
      'Hà Tĩnh': LatLng(18.3431, 105.8953),         // Center
      'Cửa Lò': LatLng(18.3667, 105.7500),          // East (Beach)
      'Kỳ Anh': LatLng(18.4000, 105.7833),          // Northeast
      'Vũ Quang': LatLng(18.6500, 105.7667),        // North
      'Thiên Cầm': LatLng(18.5333, 106.0333),       // West
    },
    
    // 4. QUẢNG TRỊ (+ Quảng Bình) - Center: Quảng Bình (Đông Hà)
    'Quảng Trị': {
      'Đông Hà': LatLng(16.7500, 107.1917),         // Center (Quảng Trị)
      'Đồng Hới': LatLng(17.4583, 106.5947),        // Center (Quảng Bình)
      'Cửa Lò': LatLng(17.1500, 106.9667),          // East (Beach)
      'Vĩnh Linh': LatLng(17.0333, 106.9333),       // North (Quảng Trị)
      'Gio Linh': LatLng(16.9167, 107.1167),        // Center-North (Quảng Trị)
    },
    
    // 5. THỪA THIÊN HUẾ
    'Thừa Thiên Huế': {
      'Thành phố Huế': LatLng(16.4637, 107.5909),   // Center (Royal City)
      'Phú Nhuận': LatLng(16.5500, 107.6500),       // North
      'Phú Vang': LatLng(16.3667, 107.7500),        // East
      'Tây Lộc': LatLng(16.4333, 107.5333),         // West
      'A Lưới': LatLng(16.5833, 107.4000),          // Southwest
    },
    
    // 6. THÀNH PHỐ ĐÀ NẴNG (+ Quảng Nam)
    'Thành phố Đà Nẵng': {
      'Hải Châu': LatLng(16.0667, 108.2167),        // Center (Đà Nẵng)
      'Thanh Khê': LatLng(16.0500, 108.1833),       // West (Đà Nẵng)
      'Sơn Trà': LatLng(16.1000, 108.2667),         // Northeast (Đà Nẵng)
      'Ngũ Hành Sơn': LatLng(16.0333, 108.2833),    // East (Đà Nẵng)
      'Hội An': LatLng(15.8785, 108.3368),          // South (Quảng Nam - Ancient Town)
      'Liên Chiểu': LatLng(15.9833, 108.0833),      // Southwest (Đà Nẵng)
    },
    
    // 7. QUẢNG NGÃI (+ Kon Tum)
    'Quảng Ngãi': {
      'Quảng Ngãi': LatLng(15.1203, 108.7997),      // Center (Quảng Ngãi)
      'Dung Quất': LatLng(15.0333, 108.9167),       // Southeast (Quảng Ngãi)
      'Bình Sơn': LatLng(15.3667, 108.8333),        // North (Quảng Ngãi)
      'Sơn Tây': LatLng(15.3333, 108.4667),         // West (Quảng Ngãi)
      'Kon Tum': LatLng(14.3667, 107.9833),         // North (Kon Tum)
      'Dak To': LatLng(14.4500, 107.6833),          // Northwest (Kon Tum)
      'Lý Sơn': LatLng(15.3833, 109.1833),          // East (Quảng Ngãi - Island)
    },
    
    // 8. GIA LAI (+ Bình Định) - Center: Bình Định
    'Gia Lai': {
      'Pleiku': LatLng(13.9833, 108.0000),          // Center (Gia Lai)
      'Bình Định': LatLng(14.1588, 108.7817),       // Center (Bình Định)
      'Ia Grai': LatLng(14.0333, 107.9333),         // East (Gia Lai)
      'Ayun Pa': LatLng(13.6000, 108.2000),         // South (Gia Lai)
      'Chu Pah': LatLng(14.2333, 107.7500),         // North (Gia Lai)
      'Phú Thiện': LatLng(13.8500, 107.8500),       // West (Gia Lai)
      'Đức Cơ': LatLng(13.5000, 107.6500),          // Southwest (Gia Lai)
      'Phù Cát': LatLng(14.1333, 108.9333),         // East (Bình Định)
    },
    
    // 9. ĐẮK LẮK (+ Phú Yên)
    'Đắk Lắk': {
      'Buôn Ma Thuột': LatLng(12.6667, 108.0500),   // Center (Đắk Lắk)
      'Tuy Hòa': LatLng(13.1065, 109.3252),         // Center (Phú Yên)
      'Buôn Hồ': LatLng(12.5000, 108.1500),         // South (Đắk Lắk)
      'Lắk': LatLng(12.0333, 108.0000),             // Southwest (Đắk Lắk)
      'Cư M\'gar': LatLng(12.3333, 108.3500),       // Southeast (Đắk Lắk)
      'Krông Bông': LatLng(12.8333, 108.5000),      // East (Đắk Lắk)
      'Krông A Na': LatLng(13.1667, 108.2500),      // Northeast (Đắk Lắk)
      'Sông Cầu': LatLng(13.1600, 109.4000),        // East (Phú Yên)
    },
    
    // 10. KHÁNH HÒA (+ Ninh Thuận)
    'Khánh Hòa': {
      'Nha Trang': LatLng(12.2383, 109.1967),       // Center (Khánh Hòa)
      'Phan Rang': LatLng(11.5601, 108.9835),       // Center (Ninh Thuận)
      'Cam Ranh': LatLng(11.9333, 109.1833),        // South (Khánh Hòa)
      'Ninh Hoà': LatLng(12.3833, 109.0333),        // North (Khánh Hòa)
      'Vạn Ninh': LatLng(12.6000, 108.9333),        // Northwest (Khánh Hòa)
      'Diên Khánh': LatLng(12.1500, 109.0833),      // Southwest (Khánh Hòa)
      'Tháp Chàm': LatLng(11.8050, 109.3100),       // East (Ninh Thuận)
    },
    
    // 11. LÂM ĐỒNG (+ Đắk Nông + Bình Thuận)
    'Lâm Đồng': {
      'Đà Lạt': LatLng(11.9400, 108.4400),          // Center (Lâm Đồng)
      'Gia Nghĩa': LatLng(12.0633, 107.7033),       // Center (Đắk Nông)
      'Phan Thiết': LatLng(10.9280, 108.0968),      // Center (Bình Thuận)
      'Bảo Lộc': LatLng(11.5500, 107.7833),         // Southwest (Lâm Đồng)
      'Đức Trọng': LatLng(11.8000, 108.2500),       // South (Lâm Đồng)
      'Tại Yên': LatLng(11.8500, 108.1000),         // Southeast (Lâm Đồng)
      'Lâm Hà': LatLng(11.6667, 108.3667),          // Southeast (Lâm Đồng)
      'Đắk Hà': LatLng(11.9667, 107.5000),          // West (Đắk Nông)
      'Cư Jút': LatLng(12.0167, 107.8333),          // Southeast (Đắk Nông)
      'Tuy Phong': LatLng(11.3700, 108.7467),       // South (Bình Thuận)
    },
  };

  // ============================================================
  // METHODS FOR SELECTING LOCATIONS
  // ============================================================
  
  /// Get all provinces
  static List<String> getAllProvinces() {
    return provinceCapitals.keys.toList();
  }
  
  /// Get districts for a specific province
  static List<String> getDistrictsForProvince(String province) {
    return provincesWithDistricts[province]?.keys.toList() ?? [];
  }
  
  /// Get coordinates for a province (fallback to capital)
  static LatLng getProvinceCoordinates(String province) {
    return provinceCapitals[province] ?? const LatLng(13.9833, 108.0000);
  }
  
  /// Get coordinates for a specific district/ward
  static LatLng getDistrictCoordinates(String province, String district) {
    return provincesWithDistricts[province]?[district] ?? 
           getProvinceCoordinates(province);
  }
  
  /// Check if district exists in province
  static bool districtExistsInProvince(String province, String district) {
    return provincesWithDistricts[province]?.containsKey(district) ?? false;
  }
  
  /// Get all major cities for quick selection
  static List<String> getMajorCities() {
    return [
      'Thanh Hóa',
      'Nghệ An',
      'Hà Tĩnh',
      'Quảng Trị',
      'Thừa Thiên Huế',
      'Thành phố Đà Nẵng',
      'Quảng Ngãi',
      'Gia Lai',
      'Đắk Lắk',
      'Khánh Hòa',
      'Lâm Đồng',
    ];
  }
}

/// Helper class for quick coordinate lookup
class VietnamCoordinates {
  static LatLng getCoordinatesOrDefault(String location) {
    // Try exact province match first
    if (VietnamLocationsService.provinceCapitals.containsKey(location)) {
      return VietnamLocationsService.getProvinceCoordinates(location);
    }
    
    // Try finding in all districts
    for (final province in VietnamLocationsService.provincesWithDistricts.keys) {
      final districts = VietnamLocationsService.provincesWithDistricts[province]!;
      if (districts.containsKey(location)) {
        return districts[location]!;
      }
    }
    
    // Fallback to default Gia Lai
    return const LatLng(13.9833, 108.0000);
  }
}
