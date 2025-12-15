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
  late String selectedPrice;

  late Map<String, String> prices;

  @override
  void initState() {
    super.initState();
    // Parse giá từ order (ví dụ: "4.200.000 đ" → 4200000)
    final priceStr = widget.order.price.replaceAll(RegExp(r'[^\d]'), '');
    final priceNum = int.tryParse(priceStr) ?? 3500000;
    
    // Tính toán giá dựa trên giá đề xuất
    final low = priceNum - 300000; // Giảm 300k
    final mid = priceNum;          // Bằng giá đề xuất
    final high = priceNum + 300000; // Tăng 300k

    prices = {
      'Thấp': '${low.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
      'Trung bình': '${mid.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
      'Cao': '${high.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
    };

    selectedPrice = prices['Trung bình']!; // Default là trung bình
  }

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
            _buildOrderIdRow('Mã chuyến hàng:', widget.order.id),
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
              children: prices.entries.map((e) {
                final isSelected = selectedPrice == e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedPrice = e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
                  _paymentRow('Phí Green Route (8%):', '-${(double.parse(selectedPrice.replaceAll('.', '').replaceAll(' đ', '')) * 0.08).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ', color: Colors.red),
                  const Divider(),
                  _paymentRow('Số tiền thực nhận:', '${(double.parse(selectedPrice.replaceAll('.', '').replaceAll(' đ', '')) * 0.92).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ', bold: true),
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
                      // Kiểm tra xem đã gửi giá cho đơn này chưa
                      final waitingOrders = await OrderStatusService.getWaitingOrders();
                      final acceptedOrders = await OrderStatusService.getAcceptedOrders();
                      
                      final alreadyBid = waitingOrders.any((o) => o.id == widget.order.id) ||
                                        acceptedOrders.any((o) => o.id == widget.order.id);
                      
                      if (alreadyBid) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Bạn đã gửi giá đấu thầu cho đơn này rồi!'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Lưu đơn vào trạng thái "Đang chờ"
                      await OrderStatusService.addWaitingOrder(widget.order, selectedPrice);

                      if (!mounted) return;
                      Navigator.pop(context);

                      // Hiển thị notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi giá đấu thầu! Chờ chủ hàng phản hồi...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      widget.onBidSubmitted?.call();
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
  
  Widget _buildOrderIdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _paymentRow(String label, String value, {Color? color, bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null))]));
}