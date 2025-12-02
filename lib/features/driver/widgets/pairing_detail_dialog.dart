// lib/features/driver/widgets/pairing_detail_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/pairing_trip_model.dart';

/// HÀM TEXTFIELD DÙNG CHUNG
Widget _textField(String label, {String hint = ''}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

/// 1. DIALOG: CHỦ HÀNG ĐẶT GHÉP
class ShipperBookingDialog extends StatelessWidget {
  final PairingTripModel trip;
  const ShipperBookingDialog({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Đặt ghép hàng', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Chuyến: ${trip.from} → ${trip.to}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Còn trống: ${(trip.maxWeight - trip.usedWeight).toStringAsFixed(1)} tấn'),
          Text('Giá đề xuất: ${trip.proposedPrice}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _textField('Tải trọng cần ghép (tấn) *', hint: 'Ví dụ: 2.5'),
          _textField('Giá bạn muốn trả (đ) *', hint: 'Ví dụ: 900.000'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Hủy',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Gửi yêu cầu',
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi yêu cầu ghép hàng! Tài xế sẽ phản hồi trong 24h'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. DIALOG: TÀI XẾ XEM + CHỐT/HỦY YÊU CẦU
class OwnerRequestDialog extends StatelessWidget {
  final PairingTripModel trip;
  const OwnerRequestDialog({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Yêu cầu ghép hàng (3)', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _requestItem(context, 'Nguyễn Văn C', '2.5 tấn', '900.000 đ', Colors.green),
            _requestItem(context, 'Trần Thị D', '1.8 tấn', '650.000 đ', Colors.orange),
            _requestItem(context, 'Lê Văn E', '3.0 tấn', '1.100.000 đ', Colors.red),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Hủy chuyến ghép',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CancelConfirmDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ĐÃ SỬA: TRUYỀN CONTEXT VÀO ĐỂ DÙNG ScaffoldMessenger
  Widget _requestItem(BuildContext context, String name, String weight, String price, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$weight • $price'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã chấp nhận yêu cầu ghép hàng!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã từ chối yêu cầu'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. DIALOG: XÁC NHẬN HỦY CHUYẾN
class CancelConfirmDialog extends StatelessWidget {
  const CancelConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận hủy chuyến?', style: TextStyle(color: Colors.red)),
      content: const Text('Bạn có chắc chắn muốn hủy chuyến ghép này?\nCác chủ hàng đã đặt sẽ được thông báo.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Không'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context); // Đóng confirm
            Navigator.pop(context); // Đóng danh sách yêu cầu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hủy chuyến ghép hàng!'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: const Text('Hủy chuyến', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// 4. DIALOG: TÀI XẾ TẠO CHUYẾN GHÉP HÀNG MỚI
class CreatePairingDialog extends StatelessWidget {
  const CreatePairingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tạo chuyến ghép hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Hướng dẫn
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chuyến ghép hàng là gì?', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Khi xe về (ví dụ: sau khi giao hàng ở Đắk Lắk, xe cần về Quy Nhơn), container thường rỗng...'),
                    SizedBox(height: 8),
                    Row(children: [Icon(Icons.check, color: Colors.green, size: 16), Text(' Thay vì về rỗng')]),
                    Row(children: [Icon(Icons.check, color: Colors.green, size: 16), Text(' Tăng thu nhập')]),
                    Row(children: [Icon(Icons.check, color: Colors.green, size: 16), Text(' Tiết kiệm xăng')]),
                    Row(children: [Icon(Icons.check, color: Colors.green, size: 16), Text(' Chi phí được chia sẻ')]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Thông tin xe
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin xe của bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Biển số xe: 77A-8977'),
                    Text('Loại xe: Xe tải nặng'),
                    Text('Tải trọng tối đa: 5 tấn'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('Thông tin chuyến đi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _textField('Điểm xuất phát *'),
              _textField('Điểm đến *'),
              _textField('Ngày giờ khởi hành *'),
              _textField('Tổng giá cước đề xuất (đ) *', hint: 'Ví dụ: 1.800.000'),
              _textField('Tải trọng tối đa (tấn) *', hint: 'Ví dụ: 5.0'),

              const SizedBox(height: 12),
              const Text(
                'Lưu ý: Sau khi tạo, chuyến ghép hàng sẽ hiển thị cho các chủ hàng. Bạn sẽ nhận được thông báo khi có chủ hàng đặt ghép.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Hủy',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Tạo chuyến ghép hàng',
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tạo chuyến ghép hàng thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}