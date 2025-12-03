// lib/features/driver/widgets/bid_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/order_model.dart';
import '../services/order_status_service.dart';

class BidBottomSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onBidSubmitted;
  final VoidCallback? onBidAccepted;

  const BidBottomSheet({
    super.key,
    required this.order,
    this.onBidSubmitted,
    this.onBidAccepted,
  });

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  String selectedPrice = '3.500.000 đ';

  final Map<String, String> prices = {
    'Thấp': '3.150.000 đ',
    'Trung bình': '3.500.000 đ',
    'Cao': '3.850.000 đ',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, color: Colors.grey[300])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đặt giá thầu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // Thông tin đơn
            _infoRow('Mã chuyến hàng:', widget.order.id),
            _infoRow('Tuyến đường:', '${widget.order.from} - ${widget.order.to}'),
            _infoRow('Khối lượng:', widget.order.weight),
            _infoRow('Ngày nhận:', widget.order.receiveDate),
            _infoRow('Ngày giao:', widget.order.deliverDate),
            const SizedBox(height: 16),

            const Text('Giá chủ hàng đề xuất', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(widget.order.price, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),

            const Text('Chọn giá đấu thầu của bạn', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prices.entries.map((e) {
                final isSelected = selectedPrice == e.value;
                return GestureDetector(
                  onTap: () => setState(() => selectedPrice = e.value),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(e.key, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black)),
                        Text(e.value, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _paymentRow('Giá đấu thầu:', selectedPrice),
                  _paymentRow('Phí Green Route (8%):', '-${(double.parse(selectedPrice.replaceAll('.', '').replaceAll(' đ', '')) * 0.08).toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}.000 đ', color: Colors.red),
                  const Divider(),
                  _paymentRow('Số tiền thực nhận:', '${(double.parse(selectedPrice.replaceAll('.', '').replaceAll(' đ', '')) * 0.92).toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}.000 đ', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: CustomButton(label: 'Hủy', onPressed: () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Gửi giá đấu thầu',
                    onPressed: () async {
                      // Lưu đơn vào trạng thái "Đang chờ"
                      await OrderStatusService.addWaitingOrder(widget.order);

                      if (!mounted) return;
                      Navigator.pop(context);

                      // Hiển thị notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi giá đấu thầu! Bạn sẽ nhận thông báo khi có cập nhật'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      widget.onBidSubmitted?.call();

                      // Giả lập: 70% trúng thầu (sau 3 giây)
                      Future.delayed(const Duration(seconds: 3), () {
                        if (DateTime.now().millisecond % 10 < 7) {
                          // Chuyển từ waiting sang accepted
                          OrderStatusService.acceptOrder(widget.order.id);
                          widget.onBidAccepted?.call();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Chúc mừng! Bạn đã trúng thầu!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]));
  Widget _paymentRow(String label, String value, {Color? color, bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null))]));
}