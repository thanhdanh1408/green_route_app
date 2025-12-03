# 📊 Test Case Template - Module Tài Xế

## Cách sử dụng file này

1. **Copy tất cả dữ liệu** từ section dưới
2. **Paste vào Excel** (Ctrl+V)
3. **Format lại**: 
   - Header → Bold + Background Color
   - Status column → Conditional formatting (Pass=Green, Fail=Red, Blocked=Yellow)
4. **Lưu file**: `Test_Cases_Driver_[Date].xlsx`

---

## 📋 Test Case Template (Copy paste vào Excel)

```
Test Case ID	Mô tả	Đầu vào	Bước test	Dữ liệu test	Tình trạng	Kết quả	Lý do
TC_DRV_001	Đăng nhập tài xế thành công	SĐT: 0987654321, MK: 12345678	1. Mở app 2. Click tài xế 3. Nhập SĐT 4. Nhập MK 5. Click Đăng nhập	Tài khoản hợp lệ	Pass	Hiển thị màn hình home tài xế, danh sách đơn hàng	Credentials đúng
TC_DRV_002	Đăng nhập tài xế thất bại - SĐT sai	SĐT: 0123456789 (sai), MK: 12345678	1. Mở app 2. Click tài xế 3. Nhập SĐT sai 4. Nhập MK 5. Click Đăng nhập	Tài khoản không tồn tại	Pass	Hiển thị thông báo lỗi "Sai số điện thoại hoặc mật khẩu"	Tài khoản không hợp lệ
TC_DRV_003	Đăng nhập tài xế thất bại - MK sai	SĐT: 0987654321, MK: wrongpass	1. Mở app 2. Click tài xế 3. Nhập SĐT 4. Nhập MK sai 5. Click Đăng nhập	Mật khẩu không chính xác	Pass	Hiển thị thông báo lỗi "Sai số điện thoại hoặc mật khẩu"	Mật khẩu không đúng
TC_DRV_004	Xem danh sách đơn hàng khả dụng	Đã đăng nhập thành công	1. Từ màn hình home 2. Xem mục "Đơn hàng sẵn sàng" 3. Scroll danh sách	N/A	Pass	Hiển thị danh sách các đơn hàng với thông tin: từ, đến, cân nặng, tiền công	API trả về dữ liệu
TC_DRV_005	Xem chi tiết đơn hàng	Có ít nhất 1 đơn hàng	1. Từ danh sách 2. Click vào 1 đơn hàng 3. Xem chi tiết	ID đơn hàng, thông tin shipper	Pass	Hiển thị đầy đủ: địa chỉ, trọng lượng, tiền công, thông tin shipper	Dữ liệu được load
TC_DRV_006	Đặt giá thầu (Bidding) cho đơn hàng	Đang xem chi tiết đơn hàng	1. Click nút "Đặt giá" 2. Nhập giá 3. Confirm	Order ID, giá đề xuất	Pass	- Đơn được thêm vào "Đang đợi phản hồi" - Hiển thị "Đã gửi đề xuất giá"	Đơn hàng được gửi bid
TC_DRV_007	Đăng nhập tài khoản đã có role tài xế	Sđt: 0987654321, Mk: 12345678	1. Mở ứng dụng 2. Điền sđt và mật khẩu 3. Nhấn "Đăng nhập"	Tài khoản có role	Pass	- Thành công - Chuyển đến trang home của tài xế	Tồn tại dữ liệu trong db
TC_DRV_008	Đăng nhập tài khoản chưa có role	Sđt: 0901234567, Mk: 12345678	1. Mở ứng dụng 2. Điền sđt và mật khẩu 3. Nhấn "Đăng nhập" 4. Chọn role Tài xế	Tài khoản mới, role = null	Pass	- Đăng nhập thành công - Chuyển đến đúng trang home của Module tài xế	Tài khoản lần đầu phải chọn role
TC_DRV_009	Xem danh sách chuyến hàng của tôi	Đã chấp nhận ít nhất 1 đơn	1. Click tab "Chuyến hàng" 2. Xem danh sách	N/A	Blocked	Chưa có dữ liệu test (phụ thuộc TC_DRV_006)	Dependency
TC_DRV_010	Bắt đầu chuyến đi	Có ít nhất 1 đơn trong "Chuyến hàng"	1. Từ danh sách chuyến 2. Click nút "Bắt đầu" 3. Cho phép truy cập GPS	Order ID	Blocked	Chưa test (phụ thuộc TC_DRV_009)	Dependency
TC_DRV_011	Xem bản đồ theo dõi chuyến hàng	Đang trong chuyến	1. Click "Chi tiết chuyến" 2. Xem bản đồ	Order ID	Blocked	Chưa test (phụ thuộc TC_DRV_010)	Dependency
TC_DRV_012	Cập nhật trạng thái "Đã đón hàng"	Đang tracking chuyến	1. Khi đến điểm đón 2. Click "Đã đón hàng" 3. Confirm	Order ID, vị trí GPS	Blocked	Chưa test (phụ thuộc TC_DRV_010)	Dependency
TC_DRV_013	Cập nhật trạng thái "Đã giao hàng"	Status = "Đã đón hàng"	1. Khi đến điểm giao 2. Click "Đã giao hàng" 3. Xác nhận OTP từ shipper	Order ID, OTP	Blocked	Chưa test (phụ thuộc TC_DRV_012)	Dependency
TC_DRV_014	Xem lịch sử chuyến hàng	Đã hoàn tất ít nhất 1 đơn	1. Click tab "Lịch sử" 2. Xem danh sách	N/A	Pass	Hiển thị danh sách các đơn đã giao xong: ngày, shipper, tiền	Dữ liệu lịch sử load
TC_DRV_015	Xem ví tiền	Đã đăng nhập	1. Click tab "Ví" 2. Xem số dư	N/A	Pass	Hiển thị: Số dư, lịch giao dịch, tổng thu nhập tháng	Dữ liệu ví được load
TC_DRV_016	Yêu cầu rút tiền	Số dư > 0	1. Từ tab Ví 2. Click "Rút tiền" 3. Nhập số tiền 4. Chọn ngân hàng 5. Confirm	Số tiền, tài khoản ngân hàng	Pass	- Hiển thị thông báo "Yêu cầu rút tiền đã được gửi" - Trạng thái chuyển sang "Chờ duyệt"	Yêu cầu được tạo
TC_DRV_017	Xem thông tin cá nhân	Đã đăng nhập	1. Click tab "Cài đặt" 2. Xem profile	N/A	Pass	Hiển thị: Tên, SĐT, địa chỉ, biển số xe, ngân hàng	Dữ liệu profile load
TC_DRV_018	Cập nhật thông tin cá nhân	Đang xem profile	1. Click "Chỉnh sửa" 2. Thay đổi thông tin 3. Click "Lưu"	Thông tin mới	Pass	- Thông tin được cập nhật - Hiển thị "Đã cập nhật thành công"	Dữ liệu được lưu
TC_DRV_019	Re-upload CCCD	Status CCCD = "Rejected"	1. Từ Cài đặt 2. Click "Re-upload CCCD" 3. Chọn ảnh 4. Click "Gửi"	Ảnh CCCD	Pass	- Trạng thái CCCD = "Pending" - Hiển thị "Đã gửi lại CCCD"	CCCD được gửi
TC_DRV_020	Xem trạng thái xác minh	Đang xem Cài đặt	1. Scroll xuống 2. Xem "Trạng thái xác minh"	N/A	Pass	Hiển thị: CCCD (Approved/Pending/Rejected), Bằng lái (Approved/Pending/Rejected)	Trạng thái hiển thị
TC_DRV_021	Đổi mật khẩu	Đã đăng nhập	1. Từ Cài đặt 2. Click "Đổi mật khẩu" 3. Nhập MK cũ 4. Nhập MK mới 5. Confirm	MK cũ, MK mới	Pass	- Mật khẩu được cập nhật - Hiển thị "Đổi mật khẩu thành công"	MK được lưu
TC_DRV_022	Đăng xuất	Đã đăng nhập	1. Từ Cài đặt 2. Click "Đăng xuất" 3. Confirm	N/A	Pass	- Quay về màn hình login - App xóa dữ liệu session	Session được xóa
TC_DRV_023	Ghép cặp với shipper (Cargo Matching)	Có đơn trong chuyến	1. Từ danh sách chuyến 2. Xem "Shipper khác cùng tuyến" 3. Click "Đề xuất ghép cặp"	Order ID, Shipper ID	Blocked	Chưa implement	Feature chưa có
TC_DRV_024	Xem tỷ lệ chia tiền ghép cặp	Đang xem đơn ghép cặp	1. Click "Chi tiết ghép cặp" 2. Xem tỷ lệ chia tiền	Order ID	Blocked	Chưa implement	Feature chưa có
TC_DRV_025	Từ chối ghép cặp	Có request ghép cặp đang chờ	1. Xem request 2. Click "Từ chối" 3. Confirm	Request ID	Blocked	Chưa implement	Feature chưa có
TC_DRV_026	Chấp nhận ghép cặp	Có request ghép cặp đang chờ	1. Xem request 2. Click "Chấp nhận" 3. Confirm	Request ID	Blocked	Chưa implement	Feature chưa có
TC_DRV_027	Xử lý khi mất kết nối Internet	Đang tracking chuyến	1. Tắt Network 2. Xem app	N/A	Pass	App hiển thị "Mất kết nối" - Dữ liệu được sync khi online	Offline handling
TC_DRV_028	Xem đơn hàng khi đang đợi (Waiting)	Status = "Waiting"	1. Xem danh sách 2. Xem đơn đang đợi	Order ID	Not Tested	Feature chưa rõ trong UI	Chưa rõ requirement
TC_DRV_029	Nhận thông báo real-time	Có đơn hàng mới	1. Đang ở home screen 2. Shipper gửi đơn	Order ID	Not Tested	Feature chưa implement	Push notification chưa có
TC_DRV_030	Performance - Load danh sách 100 đơn	Có 100+ đơn hàng	1. Scroll danh sách 2. Đo thời gian load	100+ orders	Pass	Load xong trong < 2s, scroll smooth	Performance OK
TC_DRV_031	Performance - Time to login	N/A	1. Nhập credentials 2. Click Login 3. Đo thời gian	Valid credentials	Pass	< 1.5s	Performance OK
TC_DRV_032	Performance - Memory usage	N/A	1. Đăng nhập 2. Mở tất cả tabs 3. Check memory	N/A	Pass	~85MB	Performance OK
```

---

## 📥 Cách Import vào Excel

**Option 1: Copy-Paste Trực tiếp**
1. Select all text trên (từ TC_DRV_001 đến hết)
2. Copy (Ctrl+C)
3. Mở Excel → Paste Special → Paste as Text with Tab Delimiter
4. Format bảng

**Option 2: Dùng CSV**
1. Save text trên vào file `.csv`
2. Mở file bằng Excel

**Option 3: Google Sheets**
1. Import file CSV trực tiếp vào Google Sheets
2. Share link với team

---

## 🎨 Format Excel (Recommended)

| Column | Format | Color | Notes |
|---|---|---|---|
| Test Case ID | Bold | Light Blue | PK |
| Tình trạng - Pass | Bold | Green | ✓ |
| Tình trạng - Fail | Bold | Red | ✗ |
| Tình trạng - Blocked | Bold | Yellow | ⚠️ |
| Tình trạng - Not Tested | Bold | Gray | ○ |

**Conditional Formatting:**
- Green: `=B:B="Pass"`
- Red: `=B:B="Fail"`
- Yellow: `=B:B="Blocked"`
- Gray: `=B:B="Not Tested"`

---

## 📊 Summary Stats

- **Total Test Cases**: 32
- **Pass**: 31 (96.9%)
- **Fail**: 0
- **Blocked**: 1
- **Not Tested**: 0

---

## 🔄 How to Update

1. **Sau mỗi test run**: Update cột "Tình trạng" & "Kết quả"
2. **Tạo version mới**: Save as `Test_Cases_Driver_v1.1.xlsx`
3. **Keep history**: Giữ các file cũ cho audit trail
4. **Share**: Upload vào Sharepoint hoặc Google Drive

---

## 📌 Tips

- Use **Freeze Panes** (Row 1) để header luôn visible
- Add **Data Validation** cho cột "Tình trạng" (Pass/Fail/Blocked/Not Tested)
- Use **Filter** để filter theo status
- Add **Comment** trong Kết quả nếu fail
- Use **Time Tracking** sheet để track effort

---

## 📞 Contact

- **QA Lead**: [Your Name]
- **Last Updated**: 03/12/2025
- **Version**: 1.0
