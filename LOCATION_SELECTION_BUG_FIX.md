# Fix: Lỗi Hiển Thị Sai Địa Điểm Đặt Hàng Ghép

## 📋 Mô Tả Vấn Đề

### Lỗi Phát Hiện
**Khi đặt hàng ghép:**
- Chủ hàng chọn: **Quảng Ngãi → Khánh Hòa**
- Nhưng lịch sử hiển thị: **Gia Lai → Đắk Lắk** ❌

### Nguyên Nhân Chính
Có 3 lỗi cộng hưởng gây ra vấn đề này:

#### 1. Lỗi trong `confirm_booking_screen.dart` (dòng 218-219)
```dart
// ❌ SAI - Lấy route của tài xế thay vì địa điểm chủ hàng chọn
from: '${widget.driver['route']?.toString().split('→')[0].trim() ?? ''}',
to: '${widget.driver['route']?.toString().split('→').last.trim() ?? ''}',
```

Mỗi khi chủ hàng gửi yêu cầu booking, nó lấy tuyến đường của **tài xế** (Gia Lai → Đắk Lắk) thay vì **địa điểm chủ hàng chọn** (Quảng Ngãi → Khánh Hòa).

#### 2. Lỗi trong `create_order_screen.dart` (dòng 232-238)
```dart
// ❌ SAI - Dùng giá trị mặc định khi không chọn
from: _selectedFromProvince ?? 'Gia Lai',  
to: _selectedToProvince ?? 'Đắk Lắk',
```

Nếu người dùng không chọn địa điểm, nó sẽ dùng các giá trị mặc định Gia Lai và Đắk Lắk.

#### 3. Lỗi trong `confirm_booking_screen.dart` (dòng 47-51)
```dart
// Initialize default coordinates
_fromCoordinates = const LatLng(13.9833, 108.0000); // Pleiku, Gia Lai
_toCoordinates = const LatLng(12.6667, 108.0500);   // Buôn Ma Thuột, Đắk Lắk
```

Tọa độ mặc định được khởi tạo cứng với Gia Lai → Đắk Lắk, không lấy từ driver's route.

---

## 🔧 Fix Áp Dụng

### Fix 1: confirm_booking_screen.dart
**Dòng 198-209** - Sửa gọi API BookingService:

```dart
// ✅ ĐÚNG - Lấy từ địa điểm chủ hàng chọn
await BookingService.createBookingRequest(
  // ... other params ...
  from: _selectedFromProvince ?? 'Không rõ',  // Use shipper's choice
  to: _selectedToProvince ?? 'Không rõ',      // Use shipper's choice
  fromDetail: _fromCtrl.text.trim(),
  toDetail: _toCtrl.text.trim(),
  // ... rest of params ...
);
```

**Dòng 40-53** - Sửa khởi tạo tọa độ:

```dart
@override
void initState() {
  super.initState();
  // ... price calculation ...
  
  // ✅ ĐÚNG - Lấy từ driver's route
  final driverRoute = widget.driver['route']?.toString() ?? 'Gia Lai → Đắk Lắk';
  final routeParts = driverRoute.split('→');
  final driverFromProvince = routeParts.isNotEmpty ? routeParts[0].trim() : 'Gia Lai';
  final driverToProvince = routeParts.length > 1 ? routeParts[1].trim() : 'Đắk Lắk';
  
  // Initialize coordinates from driver's provinces
  _fromCoordinates = VietnamLocationsService.getProvinceCoordinates(driverFromProvince);
  _toCoordinates = VietnamLocationsService.getProvinceCoordinates(driverToProvince);
}
```

### Fix 2: create_order_screen.dart  
**Dòng 144-265** - Thêm validation và sửa fallback:

```dart
// ✅ ĐÚNG - Kiểm tra validate trước khi submit
if (_selectedFromProvince == null || _selectedToProvince == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Vui lòng chọn cả điểm nhận và điểm giao hàng'),
      backgroundColor: Colors.red,
    ),
  );
  setState(() => _loading = false);
  return;
}

// Save coordinates
await prefs.setDouble('order_from_lat_${shipperPhone}_temp', _fromCoordinates.latitude);
// ... other coordinate saves ...

// ✅ ĐÚNG - Sử dụng non-nullable values
OrderPoolService.instance.addOrder(
  type: OrderType.normal,
  from: _selectedFromProvince!,  // Guaranteed to have value
  to: _selectedToProvince!,      // Guaranteed to have value
  // ... rest of params ...
);
```

---

## 🎯 Kết Quả Sau Fix

### Test Case
1. Chủ hàng chọn: **Bình Sơn, Quảng Ngãi → Nha Trang, Khánh Hòa**
2. Tài xế chấp nhận đơn hàng
3. Đơn hàng chuyển sang **Lịch Sử**

### Kết Quả Mong Đợi
- ✅ Lịch sử hiển thị: **"Quảng Ngãi - Khánh Hòa"** (CORRECT)
- ✅ Map hiển thị: **Bình Sơn → Nha Trang coordinates** (CORRECT)
- ✅ Chi tiết đơn: **"Bình Sơn, Quảng Ngãi → Nha Trang, Khánh Hòa"** (CORRECT)

---

## 📁 Files Modified

| File | Dòng | Thay Đổi |
|------|------|---------|
| `lib/features/shipper/screens/confirm_booking_screen.dart` | 40-53 | Sửa khởi tạo tọa độ từ driver's route |
| `lib/features/shipper/screens/confirm_booking_screen.dart` | 198-209 | Sửa gọi BookingService để dùng shipper's location |
| `lib/features/shipper/screens/create_order_screen.dart` | 144-265 | Thêm validation và sửa fallback |

---

## 🧪 Testing Checklist

- [ ] Chủ hàng có thể chọn 2 tỉnh khác nhau bằng LocationPickerWidget
- [ ] Coordinates được hiển thị chính xác trong LocationPickerWidget
- [ ] Đặt hàng ghép - Yêu cầu được gửi thành công
- [ ] Tài xế thấy yêu cầu trong danh sách pending
- [ ] Tài xế chấp nhận yêu cầu thành công
- [ ] Đơn hàng xuất hiện trong Lịch Sử của chủ hàng
- [ ] Lịch sử hiển thị province names ĐÚNG (không còn Gia Lai - Đắk Lắk)
- [ ] Map trong chi tiết đơn hiển thị coordinates ĐÚNG
- [ ] Tạo đơn bình thường - Cũng được fix, không còn dùng Gia Lai/Đắk Lắk khi không chọn

---

## 🔍 Root Cause Analysis

**Data Flow Before Fix:**
```
Chủ hàng chọn Quảng Ngãi → Khánh Hòa
  ↓
Chọn Confirm Booking
  ↓
confirm_booking_screen lấy driver.route (Gia Lai → Đắk Lắk) ❌
  ↓
BookingService.createBookingRequest() với from='Gia Lai', to='Đắk Lắk'
  ↓
Lưu vào shipper_waiting_orders
  ↓
Lịch sử hiển thị: "Gia Lai - Đắk Lắk" ❌
```

**Data Flow After Fix:**
```
Chủ hàng chọn Quảng Ngãi → Khánh Hòa
  ↓
Chọn Confirm Booking
  ↓
confirm_booking_screen lấy _selectedFromProvince & _selectedToProvince ✅
  ↓
BookingService.createBookingRequest() với from='Quảng Ngãi', to='Khánh Hòa'
  ↓
Lưu vào shipper_waiting_orders
  ↓
Lịch sử hiển thị: "Quảng Ngãi - Khánh Hòa" ✅
```

---

**Status**: ✅ FIXED - December 15, 2025
