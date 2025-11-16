// lib/features/driver/widgets/order_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/order_model.dart';
import 'bid_bottom_sheet.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isBidding;
  final VoidCallback? onBid;

  const OrderCard({
    super.key,
    required this.order,
    this.isBidding = false,
    this.onBid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TIÊU ĐỀ + MÃ ĐƠN
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.from} → ${order.to}',
                        style: AppTextStyle.headline2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '#${order.id}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),

            // THÔNG TIN CHI TIẾT
            _buildInfoRow('Từ:', order.fromDetail),
            _buildInfoRow('Đến:', order.toDetail),
            _buildInfoRow('Tải trọng:', '${order.weight} tấn'),
            const SizedBox(height: 12),

            // GIÁ + NGÀY
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.red[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  order.price,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nhận: ${order.receiveDate} → Giao: ${order.deliverDate}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // NÚT ĐẶT GIÁ HOẶC ĐANG CHỜ
            Align(
              alignment: Alignment.centerRight,
              child: isBidding
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Đang chờ phản hồi',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 140,
                      height: 50,
                      child: CustomButton(
                        label: 'Đặt giá',
                        onPressed: onBid ??
                            () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => BidBottomSheet(
                                  order: order,
                                  onBidSubmitted: () {
                                    // Sẽ được gọi từ parent
                                  },
                                ),
                              );
                            },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}