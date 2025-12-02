// lib/features/driver/widgets/bid_reject_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_button.dart';

class BidRejectDialog extends StatelessWidget {
  final String orderId;
  const BidRejectDialog({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cancel, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gửi giá thầu bị từ chối', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Rất tiếc, chủ hàng đã chọn giá thầu khác cho chuyến $orderId.'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: CustomButton(label: 'Đóng', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: CustomButton(label: 'Tìm chuyến khác', onPressed: () => Navigator.pop(context))),
            ],
          ),
        ],
      ),
    );
  }
}