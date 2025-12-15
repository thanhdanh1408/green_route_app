# Tính năng Hủy Đơn Hàng (Order Cancellation Feature)

## 📋 Tổng quan

Tính năng cho phép **Tài xế** yêu cầu hủy đơn hàng với lý do cụ thể, sau đó **Admin** xem xét và phê duyệt hoặc từ chối yêu cầu.

## 🎯 Flow hoạt động

```
Tài xế → Lịch sử → Chi tiết đơn hàng → Yêu cầu hủy đơn
   ↓
Chọn lý do hủy từ danh sách
   ↓
Gửi yêu cầu
   ↓
Status đơn: "pending_cancellation"
   ↓
Admin → Yêu cầu hủy đơn → Xem danh sách
   ↓
Admin duyệt HOẶC từ chối
   ↓
Nếu DUYỆT: Status = "cancelled"
Nếu TỪ CHỐI: Status quay lại "accepted"/"delivering"
```

## 👨‍✈️ Phía Tài xế

### 1. Màn hình Chi tiết Đơn hàng (TripTrackingScreen)

**File**: `lib/features/driver/screens/trip_tracking_screen.dart`

**Tính năng mới**:
- Nút "Yêu cầu hủy đơn hàng" (màu đỏ, outline button)
- Chỉ hiển thị khi `currentStep < 3` (chưa hoàn thành)
- Khi bấm → Hiển thị dialog chọn lý do

### 2. Dialog Chọn Lý do Hủy

**Các lý do có sẵn**:
1. Shipper yêu cầu hủy
2. Xe gặp sự cố
3. Thời tiết xấu, không thể vận chuyển
4. Hàng hóa không đúng mô tả
5. Không liên lạc được với chủ hàng
6. Lý do khác (nhập text tự do)

**UI Components**:
- RadioListTile cho mỗi lý do
- TextField cho "Lý do khác"
- Info banner: "Yêu cầu hủy sẽ được gửi đến Admin để xem xét và phê duyệt"

**Validation**:
- Phải chọn lý do
- Nếu chọn "Lý do khác" → Phải nhập text

**Action**: Gọi service để tạo yêu cầu hủy

### 3. Service Methods

#### OrderStatusService (Đơn thường)

**File**: `lib/features/driver/services/order_status_service.dart`

**Method mới**: `requestCancelOrder()`

```dart
static Future<void> requestCancelOrder({
  required String orderId,
  required String reason,
}) async {
  // 1. Update order status in driver_bids → "pending_cancellation"
  // 2. Update order status in shipper_received_bids → "pending_cancellation"
  // 3. Create cancel request in 'cancel_requests' storage
  // 4. Notify stream listeners
}
```

**Data structure** (cancel request):
```dart
{
  'id': '${orderId}_cancel_${timestamp}',
  'orderId': 'order123',
  'orderType': 'regular',
  'requestedBy': 'driver',
  'driverId': '0987654321',
  'reason': 'Xe gặp sự cố',
  'status': 'pending',
  'requestedAt': '2025-12-15T10:30:00.000Z',
}
```

#### EmptyTripService (Đơn ghép)

**File**: `lib/features/driver/services/empty_trip_service.dart`

**Method mới**: `requestCancelTrip()`

```dart
static Future<void> requestCancelTrip({
  required String tripId,
  required String reason,
}) async {
  // 1. Update trip status in empty_trips → "pending_cancellation"
  // 2. Create cancel request in 'cancel_requests' storage
  // 3. Notify stream listeners
}
```

**Data structure** (same as regular):
```dart
{
  'id': '${tripId}_cancel_${timestamp}',
  'orderId': 'trip456',
  'orderType': 'consolidated',
  'requestedBy': 'driver',
  'driverId': '0987654321',
  'reason': 'Thời tiết xấu',
  'status': 'pending',
  'requestedAt': '2025-12-15T10:30:00.000Z',
}
```

## 👨‍💼 Phía Admin

### 1. Màn hình Yêu cầu Hủy Đơn (CancelRequestsScreen)

**File**: `lib/features/admin/screens/cancel_requests_screen.dart`

**Tính năng**:
- Hiển thị danh sách yêu cầu hủy đơn (status = 'pending')
- Sort theo thời gian (mới nhất trước)
- Pull-to-refresh

**Card hiển thị thông tin**:
- Badge: Loại đơn (Đơn thường/Đơn ghép)
- Badge: Người yêu cầu (Tài xế/Chủ hàng)
- Mã đơn hàng
- Thời gian yêu cầu
- Lý do hủy (trong box màu xám)
- 2 nút: "Từ chối" và "Duyệt"

### 2. Action: Duyệt yêu cầu

**Process**:
1. Show confirmation dialog
2. Update cancel request status → "approved"
3. Update order/trip status:
   - **Đơn thường**: Update trong `driver_bids` và `shipper_received_bids` → status = "cancelled"
   - **Đơn ghép**: Update trong `empty_trips` → status = "cancelled"
4. Add metadata: `cancelledAt`, `cancelledBy: 'admin'`
5. Show success message
6. Reload list

### 3. Action: Từ chối yêu cầu

**Process**:
1. Show confirmation dialog
2. Update cancel request status → "rejected"
3. Restore order/trip status:
   - **Đơn thường**: Quay lại "accepted"
   - **Đơn ghép**: Quay lại "delivering"
4. Remove cancel metadata: `cancelReason`, `cancelRequestedAt`, `cancelRequestedBy`
5. Show success message
6. Reload list

### 4. Admin Home Screen Integration

**File**: `lib/features/admin/screens/admin_home_screen.dart`

**Thêm card mới**:
```dart
_AdminCard(
  icon: Icons.cancel_presentation,
  title: 'Yêu cầu hủy đơn',
  subtitle: 'Quản lý yêu cầu hủy đơn hàng',
  color: Colors.orange,
  onTap: () => Navigator.push(...),
),
```

## 📦 Data Storage

### SharedPreferences Keys

1. **cancel_requests**: List<String>
   - Lưu tất cả yêu cầu hủy đơn
   - JSON encoded
   - Filter by status: 'pending', 'approved', 'rejected'

2. **driver_bids**: List<String>
   - Order status: 'pending', 'accepted', 'pending_cancellation', 'cancelled', 'completed'
   - Thêm fields: `cancelReason`, `cancelRequestedAt`, `cancelRequestedBy`, `cancelledAt`, `cancelledBy`

3. **empty_trips**: List<String>
   - Trip status: 'waiting', 'delivering', 'pending_cancellation', 'cancelled', 'completed'
   - Thêm fields: `cancelReason`, `cancelRequestedAt`, `cancelRequestedBy`, `cancelledAt`, `cancelledBy`

## 🎨 UI/UX

### Driver Side

**Nút hủy đơn**:
- Vị trí: Trong section "Hành động", phía trên các action khác
- Style: OutlinedButton với border và text màu đỏ
- Icon: `Icons.cancel_outlined`
- Hiển thị: Chỉ khi step < 3 (chưa hoàn thành)

**Dialog**:
- Title: "Yêu cầu hủy đơn hàng"
- RadioListTile cho từng lý do
- TextField (conditional) cho "Lý do khác"
- Info banner màu cam
- 2 buttons: "Đóng" và "Gửi yêu cầu hủy" (màu đỏ)

### Admin Side

**Card request**:
- Border radius: 12
- Padding: 16
- 2 badges ở trên: Loại đơn + Người yêu cầu
- Icon + Text cho mã đơn và thời gian
- Box màu xám cho lý do
- Row 2 buttons: "Từ chối" (outline red) + "Duyệt" (solid green)

## 🔔 Notifications

**Driver**:
- Sau khi gửi yêu cầu: "✅ Yêu cầu hủy đơn đã được gửi! Chờ Admin phê duyệt."
- Quay về màn hình Lịch sử

**Admin**:
- Sau khi duyệt: "✅ Đã duyệt hủy đơn hàng thành công!"
- Sau khi từ chối: "✅ Đã từ chối yêu cầu hủy đơn!"

## 🧪 Testing Scenarios

### Test Case 1: Driver Request Cancel (Đơn thường)
1. Login tài xế Nguyễn Văn Nam
2. Vào Lịch sử → Tab "Đơn thường"
3. Chọn 1 đơn đang giao (status = accepted)
4. Bấm "Yêu cầu hủy đơn hàng"
5. Chọn lý do: "Xe gặp sự cố"
6. Bấm "Gửi yêu cầu hủy"
7. **Expected**: 
   - Toast: "✅ Yêu cầu hủy đơn đã được gửi!"
   - Quay về Lịch sử
   - Đơn vẫn hiển thị nhưng status = "pending_cancellation"

### Test Case 2: Admin Approve Cancel
1. Login admin
2. Vào "Yêu cầu hủy đơn"
3. Thấy request từ Test Case 1
4. Bấm "Duyệt"
5. Confirm
6. **Expected**:
   - Toast: "✅ Đã duyệt hủy đơn hàng thành công!"
   - Request biến mất khỏi danh sách
   - Đơn hàng status = "cancelled"

### Test Case 3: Admin Reject Cancel
1. Login admin
2. Vào "Yêu cầu hủy đơn"
3. Thấy 1 request
4. Bấm "Từ chối"
5. Confirm
6. **Expected**:
   - Toast: "✅ Đã từ chối yêu cầu hủy đơn!"
   - Request biến mất khỏi danh sách
   - Đơn hàng status quay lại "accepted"

### Test Case 4: Driver Request Cancel (Đơn ghép)
1. Login tài xế
2. Vào Lịch sử → Tab "Đơn ghép"
3. Chọn 1 chuyến đang giao
4. Bấm "Yêu cầu hủy đơn hàng"
5. Chọn lý do: "Thời tiết xấu"
6. Bấm "Gửi yêu cầu hủy"
7. **Expected**: Tương tự Test Case 1

### Test Case 5: Custom Reason
1. Bấm "Yêu cầu hủy đơn hàng"
2. Chọn "Lý do khác"
3. TextField xuất hiện
4. Nhập: "Chủ hàng đổi địa chỉ giao hàng"
5. Bấm "Gửi yêu cầu hủy"
6. **Expected**: Lý do được lưu đúng

## 📊 Data Flow Diagram

```
┌─────────────┐
│   Driver    │
│  (Mobile)   │
└──────┬──────┘
       │ 1. Request Cancel
       │    + orderId
       │    + reason
       ↓
┌─────────────────────────────┐
│   OrderStatusService /      │
│   EmptyTripService          │
└──────┬──────────────────────┘
       │ 2. Update Status
       │    order.status = "pending_cancellation"
       │
       │ 3. Create Cancel Request
       ↓
┌─────────────────────────────┐
│  SharedPreferences          │
│  - cancel_requests          │
│  - driver_bids / empty_trips│
└──────┬──────────────────────┘
       │
       │ 4. Admin Reviews
       ↓
┌─────────────────────────────┐
│   Admin                     │
│   (CancelRequestsScreen)    │
└──────┬──────────────────────┘
       │
       ├─── 5a. APPROVE ────────────┐
       │                            │
       │ - request.status = 'approved'
       │ - order.status = 'cancelled'
       │                            │
       └─── 5b. REJECT ─────────────┤
                                    │
         - request.status = 'rejected'
         - order.status = 'accepted'
                                    │
                                    ↓
                            ┌───────────────┐
                            │  Update DB    │
                            │  + Notify     │
                            └───────────────┘
```

## 🔒 Security & Validation

1. **Driver side**:
   - Chỉ được hủy đơn mà mình là tài xế
   - Không được hủy đơn đã hoàn thành
   - Phải nhập lý do

2. **Admin side**:
   - Chỉ admin mới truy cập được
   - Xác nhận trước khi approve/reject
   - Ghi log thời gian và người thực hiện

3. **Data integrity**:
   - Status transition logic đúng
   - Không bị duplicate requests
   - Restore đúng status khi reject

## 🎉 Summary

Tính năng hủy đơn hàng đã được implement đầy đủ với:
- ✅ Driver có thể yêu cầu hủy với lý do cụ thể
- ✅ Admin xem và quản lý yêu cầu
- ✅ Approve → Cancel order permanently
- ✅ Reject → Restore order to previous state
- ✅ Support cả đơn thường và đơn ghép
- ✅ UI/UX thân thiện với validation đầy đủ
- ✅ Error handling và loading states
