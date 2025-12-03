# Green Route App - Phân tích và Triển khai Luồng Xác thực

## Phần 1: Đã Hoàn Thành

### 1. Cấu trúc Logout (Trước đó)
- [x] Add logout method to AuthService
- [x] Add logout button to shipper settings screen
- [x] Add logout button to driver settings screen
- [x] Fix null value error in ConfirmBookingScreen

### 2. Cấu trúc Đăng nhập - HOÀN TẤT ✅
- [x] Cập nhật AuthService với phương thức `login()` xác thực SĐT + mật khẩu
- [x] LoginScreen hiển thị thông báo lỗi khi sai SĐT/mật khẩu
- [x] Điều hướng tự động đến home theo role (driver/shipper/admin)

### 3. Cấu trúc Đăng ký - HOÀN TẤT ✅
- [x] **RegisterScreen1**: Nhập SĐT → kiểm tra tồn tại/hợp lệ
- [x] **RegisterScreen2**: Nhập OTP từ SMS (test: 123456)
- [x] **RegisterPasswordScreen** (NEW): Nhập mật khẩu + nhập lại
- [x] **RegisterScreen3** (UPDATED): Upload 2 ảnh CCCD qua camera
  - Chụp ảnh từ camera với `image_picker`
  - Hiển thị preview ảnh đã chọn
  - Nút xóa để tải lại ảnh
  - Xác thực bắt buộc 2 ảnh
- [x] **BankLinkScreen** (UPDATED): Liên kết ngân hàng
  - Chọn ngân hàng từ dropdown
  - Nhập số tài khoản + tên chủ tài khoản
  - Lưu thông tin vào SharedPreferences

### 4. Chọn Module - HOÀN TẤT ✅
- [x] **RegisterShipperScreen** (UPDATED): 
  - BỎ: Nhập SĐT, mật khẩu (đã có từ RegisterScreen1)
  - THÊM: Địa chỉ, mã số thuế, giấy phép kinh doanh
  - Lưu thông tin vào SharedPreferences
  - Chuyển đến `/register_complete`

- [x] **RegisterDriverScreen** (UPDATED):
  - BỎ: Nhập SĐT, mật khẩu (đã có từ RegisterScreen1)
  - THÊM: Địa chỉ (ngoài các thông tin xe đã có)
  - Lưu thông tin vào SharedPreferences
  - Chuyển đến `/register_complete`

### 5. Quên mật khẩu - HOÀN TẤT ✅
- [x] **ForgotPasswordScreen1** (UPDATED):
  - Nhập SĐT → gửi OTP
  - Kiểm tra tài khoản tồn tại
  - Sử dụng `sendOtpForForgotPassword()`

- [x] **ForgotPasswordScreen2** (UPDATED):
  - Nhập OTP xác minh
  - Kiểm tra OTP hợp lệ

- [x] **ForgotPasswordScreen3** (EXISTING):
  - Nhập mật khẩu mới + nhập lại
  - Kiểm tra mật khẩu hợp lệ

### 6. Đổi mật khẩu - HOÀN TẤT ✅
- [x] **ChangePasswordScreen** (NEW):
  - Nhập mật khẩu cũ → kiểm tra hợp lệ
  - Nhập mật khẩu mới + nhập lại
  - Sử dụng `changePassword()` từ AuthService

### 7. AuthService - HOÀN TẤT ✅
Các phương thức mới:
- [x] `sendOtpForRegister(phone)` → kiểm tra SĐT chưa tồn tại
- [x] `sendOtpForForgotPassword(phone)` → kiểm tra SĐT tồn tại
- [x] `verifyOtp(otp)` → xác thực mã OTP
- [x] `registerNewUser(phone, password)` → tạo tài khoản mới
- [x] `resetPassword(newPassword)` → đặt lại mật khẩu
- [x] `changePassword(phone, oldPassword, newPassword)` → đổi mật khẩu
- [x] `updateRole(phone, role)` → cập nhật role user
- [x] `login(identifier, password)` → đăng nhập

## Phần 2: Kiến trúc Routes

```
/login → LoginScreen
  ├─ /register1 → RegisterScreen1
  │    ├─ /register2 → RegisterScreen2
  │         └─ /register_password → RegisterPasswordScreen
  │              └─ /register3 → RegisterScreen3
  │                   └─ /bank_link → BankLinkScreen
  │                        └─ /register_complete → RegisterCompleteScreen
  │                             ├─ /register_driver → RegisterDriverScreen
  │                             └─ /register_shipper → RegisterShipperScreen
  │
  ├─ /forgot1 → ForgotPasswordScreen1
  │    └─ /forgot2 → ForgotPasswordScreen2
  │         └─ /forgot3 → ForgotPasswordScreen3
  │
  └─ /change_password → ChangePasswordScreen

/driver_home → DriverHomeScreen
  └─ /change_password → ChangePasswordScreen (từ settings)

/shipper_home → ShipperHomeScreen
  └─ /change_password → ChangePasswordScreen (từ settings)
```

## Phần 3: Dữ liệu SharedPreferences

Khi đăng nhập thành công, lưu:
```
user_phone: "0987654321"
user_role: "driver" / "shipper"
name: "Tài xế Nguyễn Văn Nam"
address: "Gia Lai"
bank: "Techcombank"
account: "190378291234"
account_name: "NGUYEN VAN NAM"
id_status: "pending" / "approved" / "rejected"
license_status: "pending" / "approved" / "rejected" (driver only)
```

## Phần 4: Status Xác minh

Trạng thái CCCD/Giấy phép:
- `pending`: Chờ admin duyệt (không thể dùng app chức năng chính)
- `approved`: Đã được duyệt (có thể sử dụng)
- `rejected`: Bị từ chối (hiển thị nút upload lại)

## Phần 5: Cảnh báo & Tiếp theo

### Cảnh báo hiện tại
- 53 info warnings (deprecated APIs, best practices)
- Không có lỗi nghiêm trọng

### Cần làm tiếp
- [ ] Tích hợp Settings Screen hiển thị trạng thái CCCD
- [ ] Nút upload lại ảnh CCCD nếu bị reject
- [ ] Tích hợp Admin Panel để duyệt/từ chối CCCD
- [ ] Thêm camera permission requests trên Android/iOS
- [ ] Tích hợp ghép đơn hàng (matching cargo)
- [ ] Test toàn bộ flow trên thiết bị thực

## Tóm tắt thay đổi
- ✅ Hoàn thành 100% luồng đăng ký/đăng nhập
- ✅ Hoàn thành quên/đổi mật khẩu
- ✅ Tích hợp upload ảnh CCCD qua camera
- ✅ Lưu trữ thông tin user và trạng thái xác minh
- ✅ Validation đầy đủ cho tất cả input
