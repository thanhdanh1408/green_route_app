# 📋 Quy trình Đặt Giá Thầu & Lịch Sử Đơn Hàng

## ✅ Tính năng mới

### 1. **Khi tài xế đặt giá thầu**
   - ✓ Hiện dialog "Chờ phản hồi" trong 2 giây
   - ✓ **NEW**: Tự động thêm đơn vào lịch sử với trạng thái **"Đang chờ"** (màu xanh)
   - ✓ Đơn được lưu trong `SharedPreferences` (key: `waiting_orders`)

### 2. **Hiển thị trong Lịch Sử Chuyến**
   - **Đang chờ** (Xanh 🔵): Các đơn vừa đặt giá thầu, chờ shipper phản hồi
   - **Hoàn thành** (Xanh lá 💚): Đơn đã giao thành công
   - **Đang vận chuyển** (Cam 🟠): Đơn đã trúng thầu, đang vận chuyển
   - **Thất bại** (Đỏ 🔴): Đơn không trúng thầu hoặc giao thất bại

### 3. **Các trạng thái đơn hàng**
```
Danh sách đơn available
         ↓ (Đặt giá)
    Đang chờ (waiting_orders)
         ↓ (Trúng thầu - 70% xác suất)
   Đã chấp nhận (accepted_orders)
         ↓ (Giao thành công)
    Hoàn thành (completed_orders)
```

---

## 🔧 Chi tiết kỹ thuật

### **OrderStatusService** (Service mới)
```dart
// Thêm đơn vào danh sách chờ
await OrderStatusService.addWaitingOrder(orderModel);

// Chuyển từ chờ sang chấp nhận (trúng thầu)
await OrderStatusService.acceptOrder(orderId);

// Lấy danh sách đơn chờ
final waitingOrders = await OrderStatusService.getWaitingOrders();

// Xóa đơn từ chờ (từ chối)
await OrderStatusService.rejectWaitingOrder(orderId);
```

### **SharedPreferences Keys**
- `waiting_orders` - JSON list các đơn đang chờ
- `accepted_orders` - JSON list các đơn đã trúng
- `completed_orders` - JSON list các đơn hoàn tất

---

## 📱 Luồng UI

### **Trước (Old)**
```
1. Tài xế chọn đơn
2. Bấm "Đặt giá"
3. Dialog "Chờ phản hồi" 2 giây
4. ❌ Không hiển thị ở đâu
5. Lịch sử trống
```

### **Sau (New)**
```
1. Tài xế chọn đơn
2. Bấm "Đặt giá"
3. ✅ Lưu vào waiting_orders
4. Dialog "Chờ phản hồi" 2 giây
5. ✅ Hiện ngay trong tab "Lịch sử" với trạng thái "Đang chờ"
6. Nếu trúng (70%) → chuyển sang "Chấp nhận"
7. Nếu hết hạn → xóa khỏi "Đang chờ"
```

---

## 🎯 Sửa chữa

| File | Thay đổi | Chi tiết |
|------|---------|---------|
| `bid_bottom_sheet.dart` | Thêm import OrderStatusService | `await OrderStatusService.addWaitingOrder()` |
| `history_screen.dart` | Đổi từ StatelessWidget → StatefulWidget | Load dữ liệu từ waiting_orders |
| `auth_service.dart` | Thêm cleanup keys | Clear `waiting_orders`, `completed_orders` khi logout |
| **order_status_service.dart** | **NEW** | Service quản lý trạng thái đơn hàng |

---

## 🧪 Cách test

### **Test Case**: Đặt giá thầu → Hiển thị lịch sử

1. **Đăng nhập** tài xế (0987654321 / 12345678)
2. **Tab "Đơn hàng"** → Chọn 1 đơn
3. **Bấm "Đặt giá"** → Chọn mức giá
4. **Bấm "Gửi giá đấu thầu"**
5. **Chờ 2 giây** (loading dialog)
6. **Chuyển sang tab "Lịch sử"**
7. ✅ **Kỳ vọng**: Đơn vừa đặt hiển thị với trạng thái **"Đang chờ"** (xanh)

### **Test Case 2**: Trúng thầu

1. Thực hiện test case 1
2. **Chờ 2 giây** → Notification "Chúc mừng! Bạn đã trúng thầu!"
3. **Chuyển sang tab "Lịch sử"** 
4. ✅ **Kỳ vọng**: Trạng thái thay đổi từ "Đang chờ" → "Chấp nhận"

---

## 📊 State Diagram

```
┌──────────────────┐
│  Đơn hàng sẵn sàng│
│  (Available)     │
└────────┬─────────┘
         │ Đặt giá (Bid)
         ↓
┌──────────────────────┐
│  Đang chờ 🔵         │
│  (waiting_orders)    │
│  - Hiện trong Lịch sử│
│  - Chờ shipper reply │
└────────┬─────────────┘
    30% ↓ 70%
 [Hết hạn] [Trúng]
    │       ↓
    │  ┌──────────────────────┐
    │  │ Chấp nhận 💚         │
    │  │ (accepted_orders)    │
    │  │ - Bắt đầu vận chuyển │
    │  │ - Update trạng thái  │
    │  └────────┬─────────────┘
    │           │ Giao xong
    │           ↓
    │      ┌──────────────────┐
    └─────→│   Hoàn thành 🔴  │
           │ (completed_orders)│
           │ - Lưu lịch sử    │
           └──────────────────┘
```

---

## 🎁 Bonus: Tính năng phát triển

**Những tính năng có thể thêm sau:**
1. **Real-time notification**: Khi shipper phản hồi bid
2. **Auto-reject**: Tự động xóa bid hết hạn (sau 24h)
3. **Counter-offer**: Shipper có thể đề xuất giá khác
4. **Bid history**: Lưu lịch tất cả các bid (thắng/thua)
5. **Rating từ Shipper**: Đánh giá tài xế sau giao hàng

---

## ✨ Cải tiến UX

- **Trước**: Người dùng không biết đơn vừa đặt ở đâu
- **Sau**: Có thể thấy ngay trong tab "Lịch sử" với status rõ ràng
- **Feedback**: Dialog loading + Snackbar notification
- **Persistence**: Dữ liệu lưu vĩnh viễn (không mất khi tắt app)

---

## 🚀 Deployment

```bash
# Commit
git add -A
git commit -m "Add order status tracking - show 'Đang chờ' in history"

# Test trên device
flutter run

# Build release
flutter build apk
```

---

## 📝 Notes

- ✅ 0 compile errors
- ✅ Backward compatible (old data vẫn work)
- ✅ Automatic cleanup khi logout
- ⚠️ Chưa implement: Real notification từ server
- ⚠️ Chưa implement: Auto-expire bids sau 24h
