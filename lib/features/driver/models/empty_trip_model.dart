import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class EmptyTrip {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String from; // e.g., "Hồ Chí Minh"
  final String to; // e.g., "Hà Nội"
  final String fromAddress; // Cụ thể: "Kho A, KCN Sóng Thần, Dĩ An, Bình Dương"
  final String toAddress; // Cụ thể: "Kho B, KCN Nội Bài, Sóc Sơn, Hà Nội"
  final String containerType; // 'container20', 'container40', 'truck', etc.
  final String capacity; // e.g., "5 tấn", "10 tấn"
  final String proposedPrice; // Giá đề xuất cho toàn chuyến
  final DateTime createdAt;
  final DateTime pickupTime;
  final DateTime deliveryTime;
  final int maxShippers; // Số lượng shipper tối đa có thể join
  final List<ShipperInTrip> joinedShippers; // Danh sách shipper đã join
  final String status; // 'open' | 'full' | 'departed' | 'completed'
  final LatLng? fromLatLng; // GPS coordinates for FROM location
  final LatLng? toLatLng; // GPS coordinates for TO location

  EmptyTrip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.from,
    required this.to,
    required this.fromAddress,
    required this.toAddress,
    required this.containerType,
    required this.capacity,
    required this.proposedPrice,
    required this.pickupTime,
    required this.deliveryTime,
    required this.maxShippers,
    this.joinedShippers = const [],
    this.status = 'open',
    this.fromLatLng,
    this.toLatLng,
  }) : createdAt = DateTime.now();

  bool get hasAvailableSlots => joinedShippers.length < maxShippers;

  double get totalJoinedWeight {
    if (joinedShippers.isEmpty) return 0.0;
    return joinedShippers
        .map((s) => double.tryParse(s.cargoWeight) ?? 0.0)
        .reduce((a, b) => a + b);
  }

  double get totalCapacityInTons {
    // Extract number from a string like "10 tấn"
    final numberPart = capacity.split(' ').first;
    return double.tryParse(numberPart) ?? 0.0;
  }

  double get availableCapacityInTons => totalCapacityInTons - totalJoinedWeight;

  double get fillPercentage {
    final totalCap = totalCapacityInTons;
    if (totalCap == 0) return 0;
    final percentage = (totalJoinedWeight / totalCap) * 100;
    return percentage.clamp(0, 100);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'from': from,
      'to': to,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'containerType': containerType,
      'capacity': capacity,
      'proposedPrice': proposedPrice,
      'createdAt': createdAt.toIso8601String(),
      'pickupTime': pickupTime.toIso8601String(),
      'deliveryTime': deliveryTime.toIso8601String(),
      'maxShippers': maxShippers,
      'joinedShippers': joinedShippers.map((s) => s.toMap()).toList(),
      'status': status,
      'fromLatLng': fromLatLng != null ? {'lat': fromLatLng!.latitude, 'lng': fromLatLng!.longitude} : null,
      'toLatLng': toLatLng != null ? {'lat': toLatLng!.latitude, 'lng': toLatLng!.longitude} : null,
    };
  }

  factory EmptyTrip.fromMap(Map<String, dynamic> map) {
    LatLng? parseLatLng(dynamic data) {
      if (data == null) return null;
      try {
        if (data is Map) {
          return LatLng(data['lat'] as double, data['lng'] as double);
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing LatLng: $e');
      }
      return null;
    }

    return EmptyTrip(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      fromAddress: map['fromAddress'] ?? 'Đang cập nhật...',
      toAddress: map['toAddress'] ?? 'Đang cập nhật...',
      containerType: map['containerType'] ?? '',
      capacity: map['capacity'] ?? '',
      proposedPrice: map['proposedPrice'] ?? '',
      pickupTime: DateTime.parse(map['pickupTime'] ?? DateTime.now().toIso8601String()),
      deliveryTime: DateTime.parse(map['deliveryTime'] ?? DateTime.now().toIso8601String()),
      maxShippers: map['maxShippers'] as int? ?? 0,
      joinedShippers: (map['joinedShippers'] as List<dynamic>?)
              ?.map((s) => ShipperInTrip.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      status: map['status'] as String? ?? 'open',
      fromLatLng: parseLatLng(map['fromLatLng']),
      toLatLng: parseLatLng(map['toLatLng']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory EmptyTrip.fromJson(String source) =>
      EmptyTrip.fromMap(jsonDecode(source) as Map<String, dynamic>);

  EmptyTrip copyWith({
    String? status,
    List<ShipperInTrip>? joinedShippers,
  }) {
    return EmptyTrip(
      id: id,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      from: from,
      to: to,
      fromAddress: fromAddress,
      toAddress: toAddress,
      containerType: containerType,
      capacity: capacity,
      proposedPrice: proposedPrice,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      maxShippers: maxShippers,
      joinedShippers: joinedShippers ?? this.joinedShippers,
      status: status ?? this.status,
      fromLatLng: fromLatLng,
      toLatLng: toLatLng,
    );
  }
}

@immutable
class ShipperInTrip {
  final String shipperId;
  final String shipperName;
  final String shipperPhone;
  final String cargoType; // Loại hàng
  final String cargoWeight; // Khối lượng (e.g., "1.5")
  final String price; // Giá nhân khác nhau cho shipper này
  final String fromDetail; // Địa điểm nhận hàng cụ thể
  final String toDetail; // Địa điểm giao hàng cụ thể
  final DateTime joinedAt;
  final String status; // 'pending' | 'approved' | 'picked' | 'delivered'

  ShipperInTrip({
    required this.shipperId,
    required this.shipperName,
    required this.shipperPhone,
    required this.cargoType,
    required this.cargoWeight,
    required this.price,
    this.fromDetail = '',
    this.toDetail = '',
    this.status = 'pending',
  }) : joinedAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'shipperId': shipperId,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'cargoType': cargoType,
      'cargoWeight': cargoWeight,
      'price': price,
      'fromDetail': fromDetail,
      'toDetail': toDetail,
      'joinedAt': joinedAt.toIso8601String(),
      'status': status,
    };
  }

  factory ShipperInTrip.fromMap(Map<String, dynamic> map) {
    return ShipperInTrip(
      shipperId: map['shipperId'] ?? '',
      shipperName: map['shipperName'] ?? '',
      shipperPhone: map['shipperPhone'] ?? '',
      cargoType: map['cargoType'] ?? '',
      cargoWeight: map['cargoWeight']?.toString() ?? '0',
      price: map['price'] ?? '',
      fromDetail: map['fromDetail'] ?? '',
      toDetail: map['toDetail'] ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}
