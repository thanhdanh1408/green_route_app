// lib/features/driver/screens/pairing_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/pairing_card.dart';
import '../services/pairing_service.dart';
import '../widgets/pairing_detail_dialog.dart'; // ĐÃ IMPORT ĐÚNG

class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: PairingService().getPairingTrips(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final trips = snapshot.data!;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary,
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Text(
                          'Ghép hàng',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text(
                          'Tạo chuyến ghép hàng cho chuyến về\nTăng thu nhập',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: '+ Tạo chuyến ghép hàng',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const CreatePairingDialog(), // ĐÃ HOẠT ĐỘNG 100%
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: trips.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có chuyến ghép hàng nào',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: trips.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PairingCard(trip: trips[i], isOwner: true),
                          ),
                        ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}