// lib/features/driver/widgets/bid_success_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_button.dart';

class BidSuccessDialog extends StatelessWidget {
  final String orderId;
  const BidSuccessDialog({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Gửi giá thầu thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Giá thầu của bạn đã được gửi đến chủ hàng cho chuyến GH009.'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: CustomButton(label: 'Quay lại Trang chủ', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: CustomButton(label: 'Xem chi tiết', onPressed: () => Navigator.pop(context))),
            ],
          ),
        ],
      ),
    );
  }
}