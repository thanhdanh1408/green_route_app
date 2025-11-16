// lib/features/driver/widgets/pairing_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/pairing_trip_model.dart';
import 'pairing_detail_dialog.dart'; // ĐÃ IMPORT ĐÚNG FILE CHỨA 2 DIALOG

class PairingCard extends StatelessWidget {
  final PairingTripModel trip;
  final bool isOwner; // true = tài xế tạo, false = chủ hàng xem

  const PairingCard({super.key, required this.trip, this.isOwner = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isOwner ? Icons.person : Icons.multiple_stop, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${trip.from} → ${trip.to}',
                    style: AppTextStyle.headline2.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: trip.usedWeight >= trip.maxWeight ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trip.usedWeight >= trip.maxWeight ? 'ĐÃ ĐẦY' : 'CÒN TRỐNG',
                    style: TextStyle(
                      color: trip.usedWeight >= trip.maxWeight ? Colors.red[800] : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Khởi hành: ${trip.departureTime}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Giá đề xuất: ${trip.proposedPrice}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.scale, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${trip.usedWeight}/${trip.maxWeight} tấn',
                  style: TextStyle(
                    color: trip.usedWeight >= trip.maxWeight ? Colors.red : Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(trip.proposedPrice, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: trip.usedWeight / trip.maxWeight,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                trip.usedWeight >= trip.maxWeight ? Colors.red : Colors.green,
              ),
              borderRadius: BorderRadius.circular(10),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                label: isOwner ? 'Xem yêu cầu đặt' : 'Đặt ghép ngay',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => isOwner
                      ? OwnerRequestDialog(trip: trip)      // HOẠT ĐỘNG 100%
                      : ShipperBookingDialog(trip: trip),   // HOẠT ĐỘNG 100%
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}