# Fix: Lỗi hiển thị sai tọa độ trong đơn hàng ghép (Consolidated Order Coordinate Bug Fix)

## 📋 Mô tả vấn đề (Problem Description)

### Test Case:
1. Đăng nhập tài khoản Chủ hàng: **Trần Thị Lan**
2. Đặt xe ghép hàng của Tài xế: **Nguyễn Văn Nam**
3. Chọn tuyến đường: **Bình Sơn, Quảng Ngãi → Nha Trang, Khánh Hòa**
4. Tài xế chấp nhận đơn hàng
5. Đơn hàng chuyển sang **Lịch Sử**

### Lỗi phát hiện (Bugs Found):
- ❌ **Lịch sử hiển thị**: "Gia Lai - Đắk Lắk" (SAI - should be "Quảng Ngãi - Khánh Hòa")
- ❌ **Map hiển thị**: Pleiku → Buôn Mê Thuột (SAI - should be Bình Sơn → Nha Trang)
- ✅ **Thông tin chi tiết**: Hiển thị ĐÚNG text

## 🔍 Root Cause Analysis

### Data Flow Problem:
```
Shipper chọn location with LocationPickerWidget
  → Gets: Province, District, Coordinates
    ↓
Old flow: sendJoinRequest() only passed TEXT (fromDetail, toDetail)
  → Lost: Coordinates
    ↓
ShipperInTrip model saved WITHOUT coordinates
    ↓
Driver approves → approveJoinRequest()
  → Used: trip.fromLatLng/toLatLng (DRIVER's coordinates)
    ↓
Result: Order created with WRONG route (showed driver's default route)
```

### Root Causes:
1. **Model incomplete**: `ShipperInTrip` class lacked `fromLatLng` and `toLatLng` fields
2. **Service signature**: `sendJoinRequest()` didn't accept coordinate parameters
3. **Approval logic**: `approveJoinRequest()` used `trip` coordinates instead of shipper's `request` coordinates
4. **UI missing**: `match_cargo_screen.dart` used plain TextFormField instead of LocationPickerWidget

## ✅ Solution Implemented

### 1. Updated Model: `empty_trip_model.dart`

Added coordinate fields to `ShipperInTrip` class:
```dart
class ShipperInTrip {
  final String shipperId;
  final String shipperName;
  // ... other fields ...
  final LatLng? fromLatLng;  // ✅ ADDED
  final LatLng? toLatLng;    // ✅ ADDED
  
  // Updated constructor
  ShipperInTrip({
    required this.shipperId,
    // ... other params ...
    this.fromLatLng,  // ✅ ADDED
    this.toLatLng,    // ✅ ADDED
  });
  
  // Updated toMap() - serialize coordinates
  Map<String, dynamic> toMap() {
    return {
      // ... other fields ...
      'fromLatLng': fromLatLng != null 
        ? {'lat': fromLatLng!.latitude, 'lng': fromLatLng!.longitude} 
        : null,
      'toLatLng': toLatLng != null 
        ? {'lat': toLatLng!.latitude, 'lng': toLatLng!.longitude} 
        : null,
    };
  }
  
  // Updated fromMap() - deserialize coordinates
  factory ShipperInTrip.fromMap(Map<String, dynamic> map) {
    LatLng? parseLatLng(dynamic value) {
      if (value is Map) {
        final lat = value['lat'];
        final lng = value['lng'];
        if (lat != null && lng != null) {
          return LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      return null;
    }
    
    return ShipperInTrip(
      // ... other fields ...
      fromLatLng: parseLatLng(map['fromLatLng']),
      toLatLng: parseLatLng(map['toLatLng']),
    );
  }
}
```

### 2. Updated Service: `empty_trip_service.dart`

#### Method 1: `sendJoinRequest()` - Accept coordinates
```dart
static Future<bool> sendJoinRequest({
  required String tripId,
  required String shipperId,
  required String shipperName,
  required String shipperPhone,
  required String cargoType,
  required String cargoWeight,
  required String price,
  required String fromDetail,
  required String toDetail,
  LatLng? fromLatLng,  // ✅ ADDED
  LatLng? toLatLng,    // ✅ ADDED
}) async {
  // ... validation ...
  
  // Create ShipperInTrip with coordinates
  final newRequest = ShipperInTrip(
    shipperId: shipperId,
    // ... other fields ...
    fromLatLng: fromLatLng,  // ✅ ADDED
    toLatLng: toLatLng,      // ✅ ADDED
  );
  
  // ... save to prefs ...
}
```

#### Method 2: `approveJoinRequest()` - Use shipper's coordinates
```dart
static Future<void> approveJoinRequest(String tripId, String shipperId) async {
  // ... find request ...
  
  // Update status with coordinates preserved
  updatedShippers[requestIndex] = ShipperInTrip(
    shipperId: request.shipperId,
    // ... other fields ...
    fromLatLng: request.fromLatLng,  // ✅ Keep shipper's coordinates
    toLatLng: request.toLatLng,
  );
  
  // ... create order ...
  
  final order = {
    'id': '${tripId}_$shipperId',
    // ... other fields ...
    'fromLatLng': request.fromLatLng != null    // ✅ CHANGED from trip.fromLatLng
      ? {'lat': request.fromLatLng!.latitude, 'lng': request.fromLatLng!.longitude} 
      : null,
    'toLatLng': request.toLatLng != null        // ✅ CHANGED from trip.toLatLng
      ? {'lat': request.toLatLng!.latitude, 'lng': request.toLatLng!.longitude} 
      : null,
  };
}
```

### 3. Updated UI: `match_cargo_screen.dart`

#### Added imports:
```dart
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/location_picker_widget.dart';
```

#### Replaced TextFormField with LocationPickerWidget:
```dart
void _showJoinDialog(EmptyTrip trip) {
  // State variables for coordinates
  String? fromProvince;
  String? fromDistrict;
  LatLng? fromCoordinates;
  String? toProvince;
  String? toDistrict;
  LatLng? toCoordinates;
  
  // ... dialog content ...
  
  // FROM location picker
  LocationPickerWidget(
    title: 'Địa điểm nhận hàng *',
    selectedProvince: fromProvince ?? trip.from,
    availableProvinces: const [],
    onLocationSelected: (province, district, coordinates) {
      setState(() {
        fromProvince = province;
        fromDistrict = district;
        fromCoordinates = coordinates;
      });
    },
  ),
  
  // TO location picker
  LocationPickerWidget(
    title: 'Điểm giao hàng *',
    selectedProvince: toProvince ?? trip.to,
    availableProvinces: const [],
    onLocationSelected: (province, district, coordinates) {
      setState(() {
        toProvince = province;
        toDistrict = district;
        toCoordinates = coordinates;
      });
    },
  ),
  
  // ... submit button ...
  
  // Validation
  if (fromProvince == null || fromDistrict == null || fromCoordinates == null) {
    // Show error
    return;
  }
  if (toProvince == null || toDistrict == null || toCoordinates == null) {
    // Show error
    return;
  }
  
  // Build location strings
  final fromDetail = '$fromDistrict, $fromProvince';
  final toDetail = '$toDistrict, $toProvince';
  
  // Send request WITH coordinates
  final success = await EmptyTripService.sendJoinRequest(
    // ... other params ...
    fromDetail: fromDetail,
    toDetail: toDetail,
    fromLatLng: fromCoordinates,  // ✅ ADDED
    toLatLng: toCoordinates,      // ✅ ADDED
  );
}
```

## 🎯 Expected Behavior After Fix

### New Data Flow:
```
Shipper chọn location with LocationPickerWidget
  → Gets: Province, District, Coordinates
    ↓
sendJoinRequest(fromDetail, toDetail, fromLatLng, toLatLng)
  → Saves: ShipperInTrip with ALL data including coordinates
    ↓
Driver approves → approveJoinRequest()
  → Uses: request.fromLatLng/toLatLng (SHIPPER's coordinates)
    ↓
Result: Order created with CORRECT route ✅
```

### Test Results Expected:
1. ✅ Chủ hàng chọn: **Bình Sơn, Quảng Ngãi → Nha Trang, Khánh Hòa**
2. ✅ Tài xế duyệt đơn
3. ✅ Lịch sử hiển thị: **"Quảng Ngãi - Khánh Hòa"** (CORRECT)
4. ✅ Map hiển thị: **Bình Sơn coordinates → Nha Trang coordinates** (CORRECT)
5. ✅ Chi tiết đơn hàng: **Bình Sơn, Quảng Ngãi → Nha Trang, Khánh Hòa** (CORRECT)

## 📝 Files Modified

1. **lib/features/driver/models/empty_trip_model.dart**
   - Added `fromLatLng` and `toLatLng` fields to `ShipperInTrip`
   - Updated `toMap()` for serialization
   - Updated `fromMap()` for deserialization

2. **lib/features/driver/services/empty_trip_service.dart**
   - Updated `sendJoinRequest()` signature to accept coordinates
   - Updated `ShipperInTrip` constructor call to include coordinates
   - Updated `approveJoinRequest()` to use shipper's coordinates instead of trip coordinates

3. **lib/features/shipper/screens/match_cargo_screen.dart**
   - Added imports: `latlong2` and `location_picker_widget`
   - Replaced TextFormField with LocationPickerWidget for location input
   - Added coordinate state variables
   - Updated validation to check coordinates
   - Updated `sendJoinRequest()` call to pass coordinates

## 🧪 Testing Checklist

- [ ] Chủ hàng có thể chọn địa điểm bằng LocationPickerWidget
- [ ] Coordinates được hiển thị trong debug logs
- [ ] Yêu cầu ghép hàng được gửi thành công
- [ ] Tài xế thấy yêu cầu trong danh sách pending
- [ ] Tài xế chấp nhận yêu cầu thành công
- [ ] Đơn hàng xuất hiện trong Lịch sử với route ĐÚNG
- [ ] Map trong chi tiết đơn hàng hiển thị coordinates ĐÚNG
- [ ] Province names hiển thị ĐÚNG (không còn "Gia Lai - Đắk Lắk")

## 🔄 Related Issues

- 11 merged provinces feature (already implemented)
- LocationPickerWidget (already implemented)
- Order history display (now fixed)

## ✨ Impact

- ✅ **Data integrity**: Coordinates now persist throughout the booking flow
- ✅ **User experience**: History and map show accurate information
- ✅ **Consistency**: All location selection now uses LocationPickerWidget
- ✅ **Reusability**: Same pattern can be applied to other booking flows
