// lib/features/shipper/screens/match_cargo_screen.dart
import 'package:flutter/material.dart';
import 'package:green_route_app/core/services/order_pool_service.dart';
import '../../../core/theme/app_theme.dart';

class MatchCargoScreen extends StatelessWidget {
  const MatchCargoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép hàng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MatchCargoItemCard(),
          SizedBox(height: 16),
          // Có thể thêm nhiều card khác ở đây sau
        ],
      ),
    );
  }
}

// CARD RIÊNG – DỄ DÙNG LẠI, ĐẸP CHUẨN ẢNH
class MatchCargoItemCard extends StatelessWidget {
  const MatchCargoItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề + icon
            Row(
              children: [
                Icon(Icons.sync_alt, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Ghép hàng tiết kiệm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhiều chủ hàng cùng thuê 1 xe – Chia sẻ chi phí',
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),

            // Mã chuyến + tuyến đường
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GF034',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đắk Lắk → Quy Nhơn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.person, color: Colors.grey),
                const Text('2 chủ hàng', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // Thông tin tài xế
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài xế: Nguyễn Văn A',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text('Xe tải trung [71A-12345]'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Khởi hành: 12-11-2025'),
            const Text('Tổng trọng: 3.2 / 5.0 tấn'),
            const SizedBox(height: 8),

            // Thanh tiến độ
            LinearProgressIndicator(
              value: 3.2 / 5.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 20),

            // Nút tham gia
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                // Trong MatchCargoItemCard → onPressed của nút
                onPressed: () {
                  OrderPoolService.instance.addOrder(
                    type: OrderType.matching,
                    from: 'Đắk Lắk',
                    to: 'Quy Nhơn',
                    goods: 'Hàng nông sản',
                    weight: '1.8',
                    price: '2.200.000',
                    pickup: '12-11-2025 08:00',
                    deliver: '13-11-2025 18:00',
                    shipperName: 'Chủ hàng Trần Lan',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã đăng yêu cầu ghép hàng! Tài xế đang xem...',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Tham gia ghép hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
