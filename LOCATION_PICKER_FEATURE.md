# LOCATION PICKER FEATURE - IMPLEMENTATION GUIDE

## Overview
Thêm chức năng chọn **phường/quận/huyện** cụ thể (không chỉ tỉnh) cho các chức năng:
1. **Tạo chuyến ghép hàng** (tài xế) - `create_empty_trip_screen.dart`
2. **Đặt xe** (chủ hàng) - `create_order_screen.dart`  
3. **Xác nhận đặt xe** (chủ hàng) - `confirm_booking_screen.dart` (optional)

Map sẽ hiển thị **chính xác** địa điểm phường/khu vực được chọn thay vì chỉ hiển thị tỉnh.

---

## Files Changed/Created

### 1. ✅ `lib/core/services/vietnam_locations_service.dart` (NEW)
**Mục đích**: Centralized database cho tất cả tỉnh, quận, huyện, phường ở Việt Nam

**Cấu trúc**:
```dart
// Vietnam provinces with capital coordinates
provinceCapitals: Map<String, LatLng>
  'Gia Lai': LatLng(13.9833, 108.0000),
  'Đắk Lắk': LatLng(12.6667, 108.0500),
  ...

// Detailed districts/wards per province
provincesWithDistricts: Map<String, Map<String, LatLng>>
  'Gia Lai': {
    'Pleiku': LatLng(13.9833, 108.0000),
    'Ia Grai': LatLng(14.0333, 107.9333),
    'Ayun Pa': LatLng(13.6000, 108.2000),
    ...
  }
  'Đắk Lắk': {
    'Buôn Ma Thuột': LatLng(12.6667, 108.0500),
    'Buôn Hồ': LatLng(12.5000, 108.1500),
    ...
  }
```

**Phương thức chính**:
- `getAllProvinces()` - Lấy tất cả tỉnh
- `getDistrictsForProvince(province)` - Lấy danh sách quận/huyện/phường
- `getProvinceCoordinates(province)` - Lấy tọa độ tỉnh
- `getDistrictCoordinates(province, district)` - Lấy tọa độ chính xác của phường

**Lợi ích**:
- Tập trung hóa dữ liệu locations
- Dễ mở rộng thêm tỉnh/quận
- Có thể reuse cho các màn hình khác

---

### 2. ✅ `lib/core/widgets/location_picker_widget.dart` (NEW)
**Mục đích**: Widget tái sử dụng để chọn vị trí địa lý

**Features**:
- Dropdown tỉnh + Dropdown phường/quận (tùy chọn)
- Hiển thị GPS coordinates
- Nút "Xem trên bản đồ" preview
- Auto-update coordinates khi chọn
- Gọi callback `onLocationSelected(province, district, coordinates)`

**Cách sử dụng**:
```dart
LocationPickerWidget(
  title: 'Điểm xuất phát *',
  selectedProvince: _selectedFrom ?? 'Tỉnh Gia Lai',
  availableProvinces: provinceOptions,
  onLocationSelected: (province, district, coordinates) {
    setState(() {
      _selectedFrom = province;
      _selectedFromDistrict = district;
      _fromCoordinates = coordinates; // ✅ Dynamic coordinates
    });
  },
)
```

**UI Components**:
- Province dropdown with icon 📍
- District dropdown (hiển thị khi có districts)
- Selected location display card
- Map preview button

---

### 3. ✅ `lib/features/driver/screens/create_empty_trip_screen.dart` (MODIFIED)
**Changes**:
- Thay thế hardcoded province dropdowns bằng `LocationPickerWidget`
- Thêm state variables:
  ```dart
  String? _selectedFromDistrict;
  String? _selectedToDistrict;
  late LatLng _fromCoordinates;
  late LatLng _toCoordinates;
  ```
- Save coordinates vào SharedPreferences:
  ```dart
  await prefs.setDouble('trip_from_lat_${driverId}_temp', _fromCoordinates.latitude);
  await prefs.setDouble('trip_from_lng_${driverId}_temp', _fromCoordinates.longitude);
  await prefs.setString('trip_from_district_${driverId}_temp', _selectedFromDistrict ?? _selectedFrom ?? '');
  ```

**Map sẽ dùng**:
- `_fromCoordinates` (LatLng) - chính xác đến phường
- `_toCoordinates` (LatLng) - chính xác đến phường

---

### 4. ✅ `lib/features/shipper/screens/create_order_screen.dart` (MODIFIED)
**Changes** (giống driver):
- Thay thế địa chỉ text fields bằng `LocationPickerWidget`
- Thêm location state variables
- Auto-populate location text từ selected province + district
- Save coordinates trước khi submit:
  ```dart
  await prefs.setDouble('order_from_lat_${shipperPhone}_temp', _fromCoordinates.latitude);
  await prefs.setDouble('order_from_lng_${shipperPhone}_temp', _fromCoordinates.longitude);
  ```

---

### 5. `lib/features/shipper/screens/confirm_booking_screen.dart` (OPTIONAL)
Nếu muốn, có thể thêm location picker ở đây cũng.

---

## How Map Uses the New Coordinates

### Before (Map hiển thị sai ❌):
```dart
// Hardcoded coordinates
fromLatLng: const LatLng(13.9833, 108.0000), // Always Gia Lai
toLatLng: const LatLng(12.6667, 108.0500),   // Always Đắk Lắk

// Map always shows Gia Lai center
FlutterMap(
  options: MapOptions(
    initialCenter: const LatLng(13.9833, 108.0000), // ❌ Fixed
    initialZoom: 8.0,
  ),
```

### After (Map hiển thị đúng ✅):
```dart
// Dynamic coordinates from location picker
fromLatLng: _fromCoordinates,  // e.g., LatLng(13.9833, 108.0000)
toLatLng: _toCoordinates,      // e.g., LatLng(12.5000, 108.1500)

// Map shows correct center based on selection
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(
      (_fromCoordinates.latitude + _toCoordinates.latitude) / 2,
      (_fromCoordinates.longitude + _toCoordinates.longitude) / 2,
    ), // ✅ Dynamic center
    initialZoom: 9.0,
  ),
```

---

## Data Flow Example

### Scenario: Tài xế tạo chuyến ghép từ Pleiku (Gia Lai) → Buôn Hồ (Đắk Lắk)

1. **User selects location**
   - Province dropdown: "Tỉnh Gia Lai"
   - District dropdown: "Pleiku"
   - `onLocationSelected` fires

2. **Widget updates state**
   ```dart
   _selectedFrom = "Tỉnh Gia Lai"
   _selectedFromDistrict = "Pleiku"
   _fromCoordinates = LatLng(13.9833, 108.0000) // ✅ Exact Pleiku coords
   ```

3. **User selects destination**
   - Province dropdown: "Tỉnh Đắk Lắk"
   - District dropdown: "Buôn Hồ"
   - `_toCoordinates = LatLng(12.5000, 108.1500)` // ✅ Exact Buôn Hồ

4. **User submits form**
   - App saves:
     ```
     trip_from_lat_driver123_temp: 13.9833
     trip_from_lng_driver123_temp: 108.0000
     trip_from_district_driver123_temp: "Pleiku"
     
     trip_to_lat_driver123_temp: 12.5000
     trip_to_lng_driver123_temp: 108.1500
     trip_to_district_driver123_temp: "Buôn Hồ"
     ```

5. **Map displays route**
   - Start marker: Pleiku ✅
   - End marker: Buôn Hồ ✅
   - OSRM draws actual road: Pleiku → Buôn Hồ ✅
   - Map center: Between Pleiku & Buôn Hồ ✅
   - Zoom: Fits entire route ✅

---

## Database Coverage

### Provinces Included:
- Tỉnh Gia Lai (6 districts)
- Tỉnh Đắk Lắk (6 districts)
- Tỉnh Kon Tum (5 districts)
- Tỉnh Khánh Hòa (5 districts)
- Tỉnh Quảng Ngãi (5 districts)
- Thành phố Đà Nẵng (6 districts)
- Thành phố Huế (5 districts)
- Tỉnh Quảng Trị (5 districts)
- Tỉnh Hà Tĩnh (5 districts)
- Tỉnh Nghệ An (5 districts)
- Tỉnh Thanh Hóa (5 districts)
- **Total**: 11 tỉnh + 58 quận/huyện/phường

### Expansion:
Easy to add more provinces/districts - chỉ cần thêm vào `provincesWithDistricts` map.

---

## Testing Checklist

### 1. **Location Picker Widget**
- [ ] Dropdown tỉnh load đúng
- [ ] Dropdown phường/quận load khi chọn tỉnh
- [ ] GPS coordinates update when district selected
- [ ] "Xem trên bản đồ" button opens map preview
- [ ] Map preview shows correct marker

### 2. **Create Empty Trip (Driver)**
- [ ] LocationPickerWidget hiển thị cho "Điểm xuất phát"
- [ ] LocationPickerWidget hiển thị cho "Điểm đến"
- [ ] Selecting district updates coordinates
- [ ] Coordinates saved to SharedPreferences
- [ ] Form validation works
- [ ] Trip creates successfully

### 3. **Create Order (Shipper)**
- [ ] LocationPickerWidget hiển thị cho "Điểm nhận hàng"
- [ ] LocationPickerWidget hiển thị cho "Điểm giao hàng"
- [ ] Text fields auto-populate from selection
- [ ] Coordinates saved correctly
- [ ] Order posts successfully

### 4. **Map Display**
- [ ] Trip tracking map shows correct start marker (from coordinates)
- [ ] Trip tracking map shows correct end marker (to coordinates)
- [ ] OSRM route draws between actual coordinates (not hardcoded)
- [ ] Map center is between start & end (not fixed Gia Lai)
- [ ] Map zoom fits entire route

### 5. **Edge Cases**
- [ ] Selecting province without district → uses province capital
- [ ] Switch between districts → coordinates update immediately
- [ ] Map preview doesn't crash on selection
- [ ] Very close start/end → still shows both markers
- [ ] Very far start/end → zoom level 9 fits route

---

## Performance Notes

- **LocationPickerWidget**: Lightweight, all data in-memory
- **Map preview**: Uses Flutter's native MapOptions (no external calls)
- **Coordinates**: Stored locally in SharedPreferences (fast)
- **OSRM routing**: Still called with accurate coordinates (no change)
- **Memory**: Minimal overhead (~2-3 KB per trip)

---

## Future Enhancements

1. **Search by address**
   - Add Google Maps/OSM Geocoding to search by street address
   - Get coordinates from address string

2. **Real GPS pin**
   - Let user tap on map to pin exact location
   - Convert map tap → coordinates

3. **Save favorites**
   - Remember user's frequent origin/destination pairs
   - Quick select from history

4. **Offline support**
   - Cache district coordinates locally
   - Works without internet for selection (map preview requires internet)

5. **More provinces**
   - Expand to all 63 provinces
   - Add more granular ward-level locations

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Location Selection** | Province only | Province + District/Ward |
| **Coordinates** | Hardcoded fixed points | Dynamic from selection |
| **Map Center** | Always Gia Lai | Between actual start/end |
| **Route Accuracy** | Wrong route displayed | Correct route from OSRM |
| **User Control** | None | Full district-level control |
| **UI** | Simple dropdown | Rich widget with preview |
| **Database** | Inline hardcoded | Centralized service |

---

## Code Examples

### Creating a trip with new location picker:

```dart
// Before:
// Map always showed Gia Lai → Đắk Lắk

// After:
// User can select:
// FROM: Tỉnh Gia Lai → Ia Grai
// TO: Tỉnh Đắk Lắk → Buôn Hồ
// Map shows correct route between those exact locations
```

### In trip_tracking_screen.dart (no changes needed):

```dart
// Already uses dynamic coordinates:
final start = widget.trip['fromLatLng'] as LatLng?;
final end = widget.trip['toLatLng'] as LatLng?;

// Now receives correct coordinates from location picker
// e.g., LatLng(13.9833, 108.0000) = Pleiku
// instead of hardcoded default
```

---

**Status**: ✅ READY FOR TESTING  
**Compatibility**: Works with existing map/GPS fixes  
**Breaking Changes**: None - backward compatible
