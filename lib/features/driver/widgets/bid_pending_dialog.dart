// lib/features/driver/widgets/bid_pending_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class BidPendingDialog extends StatelessWidget {
  const BidPendingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_filled, size: 80, color: Colors.orange[600]),
          const SizedBox(height: 20),
          const Text(
            'Đã gửi giá thầu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Giá thầu của bạn đã được gửi đến chủ hàng.\nVui lòng chờ phản hồi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          const Text('Đang chờ...', style: TextStyle(color: Colors.orange)),
        ],
      ),
    );
  }
}