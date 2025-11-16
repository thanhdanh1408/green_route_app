// lib/features/driver/models/pairing_trip_model.dart
class PairingTripModel {
  final String id;
  final String from;
  final String to;
  final String departureTime;
  final double usedWeight;
  final double maxWeight;
  final String proposedPrice;
  final String status;
  final String ownerName;
  final String ownerPhone;
  final String cargoType;

  PairingTripModel({
    required this.id,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.usedWeight,
    required this.maxWeight,
    required this.proposedPrice,
    required this.status,
    required this.ownerName,
    required this.ownerPhone,
    required this.cargoType,
  });
}