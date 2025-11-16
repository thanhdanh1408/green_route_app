// lib/features/driver/services/pairing_service.dart
import '../models/pairing_trip_model.dart';

class PairingService {
  Future<List<PairingTripModel>> getPairingTrips() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      PairingTripModel(
        id: 'GH007',
        from: 'Đắk Lắk',
        to: 'Gia Lai',
        departureTime: '12-12-2025 | 04:00 AM',
        usedWeight: 2.5,
        maxWeight: 5.0,
        proposedPrice: '1.800.000 đ',
        status: 'Đang chờ',
        ownerName: 'Trần Văn A',
        ownerPhone: '0905 678 901',
        cargoType: 'Cà phê hạt',
      ),
    ];
  }
}
