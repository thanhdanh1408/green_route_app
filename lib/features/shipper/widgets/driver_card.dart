// lib/features/shipper/widgets/driver_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DriverCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const DriverCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                data['name']?[0] ?? '?',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Chưa có tên', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${data['rating'] ?? 4.8}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('• ${data['vehicle'] ?? 'Xe tải'}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAddressRow(Icons.arrow_upward, data['fromAddress'] ?? 'N/A'),
                  _buildAddressRow(Icons.arrow_downward, data['toAddress'] ?? 'N/A'),
                  const SizedBox(height: 8),
                  Text('Giá: ${data['price'] ?? '0'}đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Text('Xuất phát: ${data['departure'] ?? ''}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

            // CHỈ ĐỂ INKWELL Ở ĐÂY THÔI → KHÔNG CÒN BẤM NHẦM NỮA!
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, color: Colors.white),
                    SizedBox(height: 4),
                    Text('Đặt xe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String address) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(address, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}