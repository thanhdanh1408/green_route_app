// lib/features/shipper/widgets/match_cargo_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MatchCargoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const MatchCargoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Ghép hàng tiết kiệm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(data['description'] ?? 'Nhiều chủ hàng cùng thuê 1 xe - Chia sẻ chi phí'),
            const Divider(height: 32),
            Text(data['route'] ?? 'Đắk Lắk → Quy Nhơn'),
            Text('Tài xế: ${data['driver']}', style: TextStyle(color: AppColors.primary)),
            Text('Loại xe: ${data['vehicle']}'),
            Text('Khởi hành: ${data['departure']}'),
            Text('Tổng trọng: ${data['weight']}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: data['progress'] ?? 0.8),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {},
                child: const Text('Tham gia ghép hàng', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}