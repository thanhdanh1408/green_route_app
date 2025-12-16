# NOTIFICATION SYSTEM DOCUMENTATION
## Green Route App - Android Notifications

---

## 📋 Overview

Tất cả 7 loại notification đã được implement hoàn chỉnh vào project. Notification sẽ hiển thị trên Android notification bar khi có các sự kiện quan trọng xảy ra.

### Notification Types Implemented (7/7 ✅)

| Loại Thông Báo | Mức Độ Ưu Tiên | Status | Chi Tiết |
|---|---|---|---|
| **Xác minh tài liệu** | ⭐⭐⭐⭐⭐ | ✅ | Khi admin duyệt/từ chối documents |
| **Rút/Nạp tiền** | ⭐⭐⭐⭐⭐ | ✅ | Khi transaction được duyệt/từ chối |
| **Đơn hàng mới** | ⭐⭐⭐⭐⭐ | ✅ | Khi có lời chào/bid từ driver |
| **Trạng thái đơn** | ⭐⭐⭐⭐ | ✅ | Khi đơn hàng thay đổi status |
| **Chuyến ghép (Empty Trip)** | ⭐⭐⭐⭐ | ✅ | Khi shipper yêu cầu join/được chấp nhận |
| **Booking/Lời chào** | ⭐⭐⭐⭐ | ✅ | Khi có bid/được chấp nhận |
| **Ví tiền** | ⭐⭐⭐ | ✅ | Khi có payment/refund/earnings |

---

## 🔧 Implementation Details

### 1. **NotificationService** (`lib/core/services/notification_service.dart`)

**Điểm khởi đầu:** Đã initialize trong `main.dart`

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();  // Initialize trước khi run app
  runApp(const ProviderScope(child: GreenRouteApp()));
}
```

**Tính năng chính:**
- ✅ Khởi tạo FlutterLocalNotificationsPlugin
- ✅ Config Android notification channel: `green_route_channel`
- ✅ Hỗ trợ custom payload cho navigation
- ✅ Color: Forest green (34, 139, 34)
- ✅ Sound, vibration, lights enabled

### 2. **Verification Notifications**

**File:** `lib/core/services/verification_service.dart`

**Khi nào:**
- Admin phê duyệt document → `showVerificationApprovedNotification()`
- Admin từ chối document → `showVerificationRejectedNotification()`

**Ví dụ Notification:**
```
Title: "Xác minh thành công"
Body: "Tài liệu CCCD của bạn đã được phê duyệt ✅"
```

**Code Example:**
```dart
// Trong approveDocument()
await NotificationService.showVerificationApprovedNotification(
  userId: doc.userId,
  documentType: doc.documentType,
);
```

### 3. **Transaction Notifications**

**File:** `lib/core/services/transaction_request_service.dart`

**Khi nào:**
- Deposit được duyệt → `showDepositStatusNotification()` + `showWalletUpdateNotification()`
- Deposit bị từ chối → `showDepositStatusNotification()`
- Withdrawal được duyệt → `showWithdrawalStatusNotification()` + `showWalletUpdateNotification()`
- Withdrawal bị từ chối → `showWithdrawalStatusNotification()`

**Ví dụ Notifications:**
```
[Deposit Approved]
Title: "Nạp tiền thành công"
Body: "Khoản nạp 500000đ đã được phê duyệt ✅"

[Wallet Update]
Title: "💳 Thanh toán thành công"
Body: "Nạp tiền được duyệt: 500000đ"
```

### 4. **Order Status Notifications**

**File:** `lib/features/driver/services/order_status_service.dart`

**Khi nào:**
- Driver gửi bid → Shipper nhận `showBidReceivedNotification()`
- Shipper chấp nhận bid → Driver nhận `showBidAcceptedNotification()`
- Order status thay đổi (assigned, in_transit, arrived, completed, cancelled) → `showOrderStatusNotification()`

**Ví dụ Notifications:**
```
[New Bid]
Title: "Có lời chào mới 💬"
Body: "Nguyễn Văn A lời chào: 150000đ"

[Order Status - In Transit]
Title: "🚗 Đơn hàng đang trên đường"
Body: "Bạn đang trên đường đón khách"
```

### 5. **Empty Trip (Chuyến Ghép) Notifications**

**File:** `lib/features/driver/services/empty_trip_service.dart`

**Khi nào:**
- Shipper gửi yêu cầu join → Driver nhận `showTripJoinRequestNotification()`
- Driver chấp nhận → Shipper nhận `showTripApprovedNotification()`
- Driver từ chối → Shipper nhận `showTripRejectedNotification()`

**Ví dụ Notifications:**
```
[Join Request - Driver side]
Title: "Shipper muốn chuyến ghép 🤝"
Body: "Nguyễn Thị B: Hà Nội → Hải Phòng"

[Approved - Shipper side]
Title: "Chuyến ghép được chấp nhận ✅"
Body: "Driver Nguyễn Văn A đã chấp nhận yêu cầu của bạn"
```

### 6. **Booking Notifications**

**File:** `lib/features/shipper/services/booking_service.dart`

**Khi nào:**
- Shipper chấp nhận booking → Driver nhận `showBidAcceptedNotification()`
- Shipper từ chối booking → Driver nhận `showBidRejectedNotification()`

**Ví dụ Notifications:**
```
[Accepted]
Title: "Lời chào được chấp nhận ✅"
Body: "Trần Thị C đã chấp nhận lời chào của bạn"

[Rejected]
Title: "Lời chào bị từ chối ❌"
Body: "Trần Thị C đã từ chối lời chào của bạn"
```

### 7. **Wallet Update Notifications**

**Tích hợp trong:** `lib/core/services/transaction_request_service.dart`

**Khi nào:**
- Khi transaction được duyệt, hiển thị wallet update
- Types: `payment`, `refund`, `reward`, `earnings`

**Ví dụ:**
```
Title: "💵 Nhận thu nhập"
Body: "Rút tiền được duyệt: 350000đ"
```

---

## 🧪 Testing Guide

### Prerequisites
- ✅ `flutter_local_notifications: ^17.0.0` (đã add vào pubspec.yaml)
- ✅ Android emulator hoặc physical device
- ✅ Android API level ≥ 21 (Android 5.0)

### Test Scenarios

#### **Scenario 1: Verification Notification** ✅
```
1. Login as: Admin (0901234567)
2. Go to: Admin → User Management → Select a user
3. Click: "Xác minh" tab
4. Click: Approve button on a document
   → 🔔 NOTIFICATION: "Xác minh thành công - Tài liệu CCCD đã được phê duyệt ✅"
5. Click: Reject button on another document with reason "Ảnh không rõ"
   → 🔔 NOTIFICATION: "Xác minh bị từ chối - Tài liệu Bằng lái: Ảnh không rõ ❌"
```

#### **Scenario 2: Transaction Notification (Deposit)** ✅
```
1. Login as: Driver (0911111111)
2. Go to: Wallet → Deposit
3. Enter amount, upload image, submit
4. Login as: Admin (0901234567)
5. Go to: Admin → Transaction Requests → Deposit tab
6. Click: Approve button
   → 🔔 Driver receives: "Nạp tiền thành công" + "Thanh toán thành công"
7. Try: Reject another deposit request
   → 🔔 Driver receives: "Nạp tiền bị từ chối"
```

#### **Scenario 3: Order Status Notification** ✅
```
1. Login as: Driver (0912222222)
2. Go to: Orders → Available orders
3. Click: Bid on an order → Submit bid
   → 🔔 Shipper receives: "Có lời chào mới 💬 - Nguyễn Văn A lời chào: 150000đ"
4. Login as: Shipper (0913333333)
5. Go to: Bookings → Received bids
6. Click: Accept button
   → 🔔 Driver receives: "Lời chào được chấp nhận ✅"
7. Admin simulates: updateOrderStatus(orderId, 'in_transit')
   → 🔔 Driver receives: "🚗 Đơn hàng đang trên đường"
```

#### **Scenario 4: Empty Trip Notification** ✅
```
1. Login as: Driver (0912222222)
2. Go to: My Trips → Create empty trip
3. Fill form: Hà Nội → Hải Phòng, submit
4. Login as: Shipper (0914444444)
5. Go to: Available trips → Find the trip
6. Click: Join request button
   → 🔔 Driver receives: "Shipper muốn chuyến ghép 🤝 - Tran Thi B: Hà Nội → Hải Phòng"
7. Driver approves request
   → 🔔 Shipper receives: "Chuyến ghép được chấp nhận ✅ - Driver Nguyễn Văn A..."
8. Try: Reject another request
   → 🔔 Shipper receives: "Chuyến ghép bị từ chối ❌"
```

#### **Scenario 5: Wallet Notification** ✅
```
1. Complete transaction approval scenario
   → 🔔 Two notifications: 
       - Deposit/Withdrawal status
       - Wallet update (Thanh toán/Earnings)
2. Check: Different emojis for different types
   - 💳 Payment
   - 💰 Refund  
   - 🎁 Reward
   - 💵 Earnings
```

---

## 📱 How to View Notifications on Android

### If notifications are not appearing:

1. **Check Android Settings:**
   ```
   Settings → Apps → Green Route App → Notifications → ON
   ```

2. **Check notification logs in Android Studio:**
   ```
   logcat filter: "NotificationService"
   ```

3. **View all notifications:**
   ```
   Pull down notification tray
   Press and hold app → Details
   ```

4. **Console debug output:**
   ```
   [Console] 📲 Notification shown: [hash_id] Title - Body
   [Console] ✅ NotificationService initialized
   ```

---

## 🔍 Debugging

### Print Logs to Check

**When notification is sent:**
```dart
print('📲 Notification shown: [$id] $title - $body');
```

**On service initialization:**
```dart
print('✅ NotificationService initialized');
```

### Using Logcat
```bash
flutter logs | grep "Notification"
flutter logs | grep "NotificationService"
```

### Check Notification ID Generation
```dart
// Each notification gets unique ID based on userId + action
// Example: userId="0912222222", action="deposit_approved"
// ID is hash % 2147483647 (positive int32)
```

---

## 📊 Notification Status Summary

| Feature | Implementation | Testing | Status |
|---------|---|---|---|
| Verification - Approve | ✅ Code added | Ready | ✅ |
| Verification - Reject | ✅ Code added | Ready | ✅ |
| Deposit - Approve | ✅ Code added | Ready | ✅ |
| Deposit - Reject | ✅ Code added | Ready | ✅ |
| Withdrawal - Approve | ✅ Code added | Ready | ✅ |
| Withdrawal - Reject | ✅ Code added | Ready | ✅ |
| New Bid - Received | ✅ Code added | Ready | ✅ |
| Bid - Accepted | ✅ Code added | Ready | ✅ |
| Bid - Rejected | ✅ Code added | Ready | ✅ |
| Order Status Change | ✅ Code added | Ready | ✅ |
| Trip Join Request | ✅ Code added | Ready | ✅ |
| Trip Approved | ✅ Code added | Ready | ✅ |
| Trip Rejected | ✅ Code added | Ready | ✅ |
| Wallet Update | ✅ Code added | Ready | ✅ |

---

## 🚀 Next Steps (Optional)

### Future Enhancements:
1. **Firebase Cloud Messaging (FCM)** - untuk notifications khi app bị close
2. **Notification History** - lưu các notifications để user xem lại
3. **Notification Preferences** - user chọn loại notification nào để nhận
4. **Deep Linking** - click notification → direct to relevant screen
5. **Group Notifications** - group same-type notifications together

---

## 📝 Files Modified

```
✅ lib/main.dart
   - Added NotificationService.initialize() in main()

✅ lib/core/services/notification_service.dart [NEW]
   - 330+ lines of notification logic

✅ lib/core/services/verification_service.dart
   - Added notifications to approveDocument() and rejectDocument()

✅ lib/core/services/transaction_request_service.dart
   - Added notifications to approveRequest() and rejectRequest()
   - Added wallet update notifications

✅ lib/features/driver/services/order_status_service.dart
   - Added notifications to driverSendBid(), shipperAcceptBid(), updateOrderStatus()

✅ lib/features/driver/services/empty_trip_service.dart
   - Added notifications to sendJoinRequest(), approveJoinRequest(), rejectJoinRequest()

✅ lib/features/shipper/services/booking_service.dart
   - Added notifications to acceptBooking() and rejectBooking()

✅ pubspec.yaml
   - Added flutter_local_notifications: ^17.0.0
```

---

## ✅ Verification Checklist

Before considering this complete:

- [ ] Project compiles with 0 errors ✅
- [ ] All 7 notification types implemented ✅
- [ ] Notifications tested on Android device/emulator
- [ ] Correct title and body for each type
- [ ] Correct emoji/icons in messages
- [ ] Notifications appear in correct order
- [ ] Sound and vibration working
- [ ] Notification channel setup correctly

---

**Status:** All notification features FULLY IMPLEMENTED and ready for testing! 🎉
