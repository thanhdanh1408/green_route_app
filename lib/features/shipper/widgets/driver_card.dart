// lib/features/shipper/widgets/driver_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/rating_service.dart';

class DriverCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const DriverCard({super.key, required this.data, this.onTap});

  @override
  State<DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<DriverCard> {
  double _rating = 0.0;
  int _ratingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    // Get driver ID from data (could be driverPhone or driverId)
    final driverId = widget.data['driverPhone'] ?? widget.data['phone'] ?? widget.data['driverId'] ?? '';
    
    if (driverId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final rating = await RatingService.getDriverRating(driverId);
    final count = await RatingService.getDriverRatingCount(driverId);

    if (mounted) {
      setState(() {
        _rating = rating;
        _ratingCount = count;
        _isLoading = false;
      });
    }
  }

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
                widget.data['name']?[0] ?? '?',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['name'] ?? 'Chưa có tên', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      if (_isLoading)
                        const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_ratingCount > 0)
                        Text(
                          '${_rating.toStringAsFixed(1)} ($_ratingCount)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      else
                        Text(
                          'Chưa có đánh giá',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      const SizedBox(width: 8),
                      Text('• ${widget.data['vehicle'] ?? 'Xe tải'}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAddressRow(Icons.arrow_upward, widget.data['fromAddress'] ?? 'N/A'),
                  _buildAddressRow(Icons.arrow_downward, widget.data['toAddress'] ?? 'N/A'),
                  const SizedBox(height: 8),
                  Text('Giá: ${widget.data['price'] ?? '0'}đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Text('Xuất phát: ${widget.data['departure'] ?? ''}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

            // CHỈ ĐỂ INKWELL Ở ĐÂY THÔI → KHÔNG CÒN BẤM NHẦM NỮA!
            InkWell(
              onTap: widget.onTap,
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