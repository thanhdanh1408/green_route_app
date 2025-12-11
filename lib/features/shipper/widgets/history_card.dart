// lib/features/shipper/widgets/history_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/rating_service.dart';
import 'rating_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final int? orderNumber; // Optional sequential number

  const HistoryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.orderNumber,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  bool _hasRated = false;
  DriverRating? _existingRating;

  @override
  void initState() {
    super.initState();
    _checkRatingStatus();
  }

  Future<void> _checkRatingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final shipperId = prefs.getString('user_phone') ?? '';
    
    final rated = await RatingService.hasRatedOrder(widget.order['id'], shipperId);
    final rating = await RatingService.getOrderRating(widget.order['id'], shipperId);
    
    setState(() {
      _hasRated = rated;
      _existingRating = rating;
    });
  }

  Future<void> _showRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final shipperId = prefs.getString('user_phone') ?? '';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        driverId: widget.order['driverPhone'] ?? '',
        driverName: widget.order['driverName'] ?? 'Tài xế',
        orderId: widget.order['id'],
        shipperId: shipperId,
      ),
    );

    if (result == true) {
      _checkRatingStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh giá thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với avatar và trạng thái
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      widget.order['tripType'] == 'consolidated' 
                          ? Icons.layers
                          : Icons.assignment,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order['route'] ?? 'N/A',
                          style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // Badge loại đơn
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.order['tripType'] == 'regular' 
                                    ? Colors.blue[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.order['tripType'] == 'regular'
                                      ? Colors.blue[300]!
                                      : Colors.orange[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.order['tripType'] == 'regular' ? 'Đơn thường' : 'Đơn ghép',
                                style: TextStyle(
                                  color: widget.order['tripType'] == 'regular'
                                      ? Colors.blue[800]
                                      : Colors.orange[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.order['goods']} • ${widget.order['weight']}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.order['statusColor'] == Colors.green
                          ? Colors.green[100]
                          : widget.order['statusColor'] == Colors.orange
                              ? Colors.orange[100]
                              : Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.order['status'] ?? 'N/A',
                      style: TextStyle(
                        color: widget.order['statusColor'] == Colors.green
                            ? Colors.green[800]
                            : widget.order['statusColor'] == Colors.orange
                                ? Colors.orange[800]
                                : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Thông tin chi tiết
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today, 'Ngày:', widget.order['date'] ?? 'N/A'),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.person,
                          'Tài xế:',
                          widget.order['driverName'] ?? 'Không có thông tin',
                        ),
                      ],
                    ),
                  ),
                  // Giá tiền
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Giá cước', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        widget.order['price'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  // Theo dõi button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Theo dõi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  // Rating button - only for completed orders
                  if (widget.order['status'] == 'Hoàn thành') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _hasRated
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.star, size: 18),
                              label: Text('${_existingRating?.rating ?? 5} ⭐'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber[700],
                                disabledForegroundColor: Colors.amber[700],
                                side: BorderSide(color: Colors.amber[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _showRatingDialog,
                              icon: const Icon(Icons.star, size: 18),
                              label: const Text('Đánh giá'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
