# Test Case - Module Tài Xế (Driver Module)

## Template Excel Format

| Test Case ID | Mô tả | Đầu vào | Bước test | Dữ liệu test | Tình trạng | Kết quả | Lý do |
|---|---|---|---|---|---|---|---|
| TC_DRV_001 | Đăng nhập tài xế thành công | SĐT: 0987654321, MK: 12345678 | 1. Mở app 2. Click tài xế 3. Nhập SĐT 4. Nhập MK 5. Click Đăng nhập | Tài khoản hợp lệ | Pass | Hiển thị màn hình home tài xế, danh sách đơn hàng | Credentials đúng |
| TC_DRV_002 | Đăng nhập tài xế thất bại - SĐT sai | SĐT: 0123456789 (sai), MK: 12345678 | 1. Mở app 2. Click tài xế 3. Nhập SĐT sai 4. Nhập MK 5. Click Đăng nhập | Tài khoản không tồn tại | Pass | Hiển thị thông báo lỗi "Sai số điện thoại hoặc mật khẩu" | Tài khoản không hợp lệ |
| TC_DRV_003 | Đăng nhập tài xế thất bại - MK sai | SĐT: 0987654321, MK: wrongpass | 1. Mở app 2. Click tài xế 3. Nhập SĐT 4. Nhập MK sai 5. Click Đăng nhập | Mật khẩu không chính xác | Pass | Hiển thị thông báo lỗi "Sai số điện thoại hoặc mật khẩu" | Mật khẩu không đúng |
| TC_DRV_004 | Xem danh sách đơn hàng khả dụng | Đã đăng nhập thành công | 1. Từ màn hình home 2. Xem mục "Đơn hàng sẵn sàng" 3. Scroll danh sách | N/A | Pass | Hiển thị danh sách các đơn hàng với thông tin: từ, đến, cân nặng, tiền công | API trả về dữ liệu |
| TC_DRV_005 | Xem chi tiết đơn hàng | Có ít nhất 1 đơn hàng | 1. Từ danh sách 2. Click vào 1 đơn hàng 3. Xem chi tiết | ID đơn hàng, thông tin shipper | Pass | Hiển thị đầy đủ: địa chỉ, trọng lượng, tiền công, thông tin shipper | Dữ liệu được load |
| TC_DRV_006 | Chấp nhận đơn hàng | Đang xem chi tiết đơn hàng | 1. Click nút "Chấp nhận" 2. Confirm | Order ID | Pass | - Đơn được thêm vào "Chuyến hàng của tôi" - Hiển thị thông báo "Đơn hàng đã được lưu" | Đơn hàng được gán cho driver |
| TC_DRV_007 | Từ chối đơn hàng | Đang xem chi tiết đơn hàng | 1. Click nút "Từ chối" 2. Chọn lý do 3. Confirm | Order ID, lý do từ chối | Pass | - Đơn được xóa khỏi danh sách - Hiển thị thông báo "Đã từ chối đơn hàng" | Đơn hàng được từ chối |
| TC_DRV_008 | Xem danh sách chuyến hàng của tôi | Đã chấp nhận ít nhất 1 đơn | 1. Click tab "Chuyến hàng" 2. Xem danh sách | N/A | Pass | Hiển thị danh sách các đơn hàng đã chấp nhận | Dữ liệu được load |
| TC_DRV_009 | Bắt đầu chuyến đi | Có ít nhất 1 đơn trong "Chuyến hàng" | 1. Từ danh sách chuyến 2. Click nút "Bắt đầu" 3. Cho phép truy cập GPS | Order ID | Pass | - GPS bắt đầu tracking - Hiển thị bản đồ thực tế | GPS được kích hoạt |
| TC_DRV_010 | Xem bản đồ theo dõi chuyến hàng | Đang trong chuyến | 1. Click "Chi tiết chuyến" 2. Xem bản đồ | Order ID | Pass | Hiển thị vị trí tài xế, điểm đón, điểm giao, route | Google Maps API hoạt động |
| TC_DRV_011 | Cập nhật trạng thái "Đã đón hàng" | Đang tracking chuyến | 1. Khi đến điểm đón 2. Click "Đã đón hàng" 3. Confirm | Order ID, vị trí GPS | Pass | - Status thay đổi thành "Đã đón hàng" - Shipper được thông báo | Status được cập nhật |
| TC_DRV_012 | Cập nhật trạng thái "Đã giao hàng" | Status = "Đã đón hàng" | 1. Khi đến điểm giao 2. Click "Đã giao hàng" 3. Xác nhận OTP từ shipper | Order ID, OTP | Pass | - Status thay đổi thành "Đã giao hàng" - Tính tiền công - Đơn được đóng | Giao dịch hoàn tất |
| TC_DRV_013 | Xem lịch sử chuyến hàng | Đã hoàn tất ít nhất 1 đơn | 1. Click tab "Lịch sử" 2. Xem danh sách | N/A | Pass | Hiển thị danh sách các đơn đã giao xong: ngày, shipper, tiền | Dữ liệu lịch sử load |
| TC_DRV_014 | Xem ví tiền | Đã đăng nhập | 1. Click tab "Ví" 2. Xem số dư | N/A | Pass | Hiển thị: Số dư, lịch giao dịch, tổng thu nhập tháng | Dữ liệu ví được load |
| TC_DRV_015 | Yêu cầu rút tiền | Số dư > 0 | 1. Từ tab Ví 2. Click "Rút tiền" 3. Nhập số tiền 4. Chọn ngân hàng 5. Confirm | Số tiền, tài khoản ngân hàng | Pass | - Hiển thị thông báo "Yêu cầu rút tiền đã được gửi" - Trạng thái chuyển sang "Chờ duyệt" | Yêu cầu được tạo |
| TC_DRV_016 | Xem thông tin cá nhân | Đã đăng nhập | 1. Click tab "Cài đặt" 2. Xem profile | N/A | Pass | Hiển thị: Tên, SĐT, địa chỉ, biển số xe, ngân hàng | Dữ liệu profile load |
| TC_DRV_017 | Cập nhật thông tin cá nhân | Đang xem profile | 1. Click "Chỉnh sửa" 2. Thay đổi thông tin 3. Click "Lưu" | Thông tin mới | Pass | - Thông tin được cập nhật - Hiển thị "Đã cập nhật thành công" | Dữ liệu được lưu |
| TC_DRV_018 | Re-upload CCCD | Status CCCD = "Rejected" | 1. Từ Cài đặt 2. Click "Re-upload CCCD" 3. Chọn ảnh 4. Click "Gửi" | Ảnh CCCD | Pass | - Trạng thái CCCD = "Pending" - Hiển thị "Đã gửi lại CCCD" | CCCD được gửi |
| TC_DRV_019 | Xem trạng thái xác minh | Đang xem Cài đặt | 1. Scroll xuống 2. Xem "Trạng thái xác minh" | N/A | Pass | Hiển thị: CCCD (Approved/Pending/Rejected), Bằng lái (Approved/Pending/Rejected) | Trạng thái hiển thị |
| TC_DRV_020 | Đổi mật khẩu | Đã đăng nhập | 1. Từ Cài đặt 2. Click "Đổi mật khẩu" 3. Nhập MK cũ 4. Nhập MK mới 5. Confirm | MK cũ, MK mới | Pass | - Mật khẩu được cập nhật - Hiển thị "Đổi mật khẩu thành công" | MK được lưu |
| TC_DRV_021 | Đăng xuất | Đã đăng nhập | 1. Từ Cài đặt 2. Click "Đăng xuất" 3. Confirm | N/A | Pass | - Quay về màn hình login - App xóa dữ liệu session | Session được xóa |
| TC_DRV_022 | Ghép cặp với shipper (Cargo Matching) | Có đơn trong chuyến | 1. Từ danh sách chuyến 2. Xem "Shipper khác cùng tuyến" 3. Click "Đề xuất ghép cặp" | Order ID, Shipper ID | Pass | - Gửi request ghép cặp tới shipper - Hiển thị "Đã gửi đề xuất" - Chờ chấp nhận | Matching request được tạo |
| TC_DRV_023 | Xem tỷ lệ chia tiền ghép cặp | Đang xem đơn ghép cặp | 1. Click "Chi tiết ghép cặp" 2. Xem tỷ lệ chia tiền | Order ID | Pass | Hiển thị: Tiền gốc, tỷ lệ chia (%), tiền mỗi bên | Tính toán chính xác |
| TC_DRV_024 | Từ chối ghép cặp | Có request ghép cặp đang chờ | 1. Xem request 2. Click "Từ chối" 3. Confirm | Request ID | Pass | - Request bị xóa - Hiển thị "Đã từ chối ghép cặp" | Request được xóa |
| TC_DRV_025 | Chấp nhận ghép cặp | Có request ghép cặp đang chờ | 1. Xem request 2. Click "Chấp nhận" 3. Confirm | Request ID | Pass | - Request được xác nhận - Shipper được thông báo - Thêm vào "Ghép cặp của tôi" | Ghép cặp được tạo |

---

## Ghi chú

### Tình trạng (Status)
- **Pass**: Test case thành công
- **Fail**: Test case thất bại
- **Blocked**: Bị chặn bởi vấn đề khác
- **Not Tested**: Chưa test

### Lý do (Reason)
- Credentials đúng/sai
- API hoạt động/lỗi
- Dữ liệu hiển thị chính xác
- Quyền truy cập
- Vấn đề hiệu năng
- Bugs phát hiện

### Các trường hợp Edge Case thêm

| TC_DRV_026 | Xử lý khi mất GPS khi tracking | Đang tracking chuyến | 1. Tắt GPS 2. Xem app | N/A | Pass | App hiển thị cảnh báo "Mất GPS" - Vẫn lưu vị trí cuối | GPS disconnect |
| TC_DRV_027 | Xử lý khi mất kết nối Internet | Đang tracking chuyến | 1. Tắt WiFi/4G 2. Xem app | N/A | Pass | App hiển thị "Mất kết nối" - Dữ liệu được sync khi online | Offline handling |
| TC_DRV_028 | Xem đơn hàng khi đang đợi (Waiting) | Status = "Waiting" | 1. Xem danh sách 2. Xem đơn đang đợi | Order ID | Pass | Hiển thị timer đếm ngược, nếu hết time thì hủy | Timer display |
| TC_DRV_029 | Nhận thông báo real-time | Có đơn hàng mới | 1. Đang ở home screen 2. Shipper gửi đơn | Order ID | Pass | Hiển thị push notification, badge +1 | Push notification |
| TC_DRV_030 | Performance - Load danh sách 100 đơn | Có 100+ đơn hàng | 1. Scroll danh sách 2. Đo thời gian load | 100+ orders | Pass | Load xong trong < 2s, scroll smooth | Performance |

---

## Cách sử dụng

1. **Copy vào Excel** - Copy bảng trên vào file Excel
2. **Điền tình trạng** - Sau mỗi lần test, update cột "Tình trạng"
3. **Ghi kết quả** - Mô tả kết quả thực tế trong cột "Kết quả"
4. **Lý do** - Nếu fail, ghi nguyên nhân
5. **Tạo Bugs** - Nếu phát hiện bug, tạo issue report

---

## Công cụ hỗ trợ

- **Test Management**: Azure DevOps, TestRail, Jira
- **Automation**: Selenium, Appium, Flutter Driver
- **Performance**: Android Studio Profiler, DevTools
- **Bug Tracking**: GitHub Issues, Jira Bugs
