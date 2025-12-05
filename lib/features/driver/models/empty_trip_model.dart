import 'dart:convert';

class EmptyTrip {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String from;
  final String to;
  final String containerType; // 'container20', 'container40', 'truck', etc.
  final String capacity; // e.g., "5 tấn", "10 tấn"
  final String proposedPrice; // Giá đề xuất cho toàn chuyến
  final DateTime createdAt;
  final DateTime pickupTime;
  final DateTime deliveryTime;
  final int maxShippers; // Số lượng shipper tối đa có thể join
  final List<ShipperInTrip> joinedShippers; // Danh sách shipper đã join
  final String status; // 'open' | 'full' | 'departed' | 'completed'

  EmptyTrip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.from,
    required this.to,
    required this.containerType,
    required this.capacity,
    required this.proposedPrice,
    required this.pickupTime,
    required this.deliveryTime,
    required this.maxShippers,
    this.joinedShippers = const [],
    this.status = 'open',
  }) : createdAt = DateTime.now();

  // Kiểm tra còn chỗ hay không
  bool get hasAvailableSlots => joinedShippers.length < maxShippers;

  // Tính % lấp đầy chuyến
  int get fillPercentage => ((joinedShippers.length / maxShippers) * 100).toInt();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'from': from,
      'to': to,
      'containerType': containerType,
      'capacity': capacity,
      'proposedPrice': proposedPrice,
      'createdAt': createdAt.toIso8601String(),
      'pickupTime': pickupTime.toIso8601String(),
      'deliveryTime': deliveryTime.toIso8601String(),
      'maxShippers': maxShippers,
      'joinedShippers': joinedShippers.map((s) => s.toMap()).toList(),
      'status': status,
    };
  }

  factory EmptyTrip.fromMap(Map<String, dynamic> map) {
    return EmptyTrip(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      driverName: map['driverName'] as String,
      driverPhone: map['driverPhone'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      containerType: map['containerType'] as String,
      capacity: map['capacity'] as String,
      proposedPrice: map['proposedPrice'] as String,
      pickupTime: DateTime.parse(map['pickupTime'] as String),
      deliveryTime: DateTime.parse(map['deliveryTime'] as String),
      maxShippers: map['maxShippers'] as int,
      joinedShippers: (map['joinedShippers'] as List<dynamic>?)
              ?.map((s) => ShipperInTrip.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      status: map['status'] as String? ?? 'open',
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
      containerType: containerType,
      capacity: capacity,
      proposedPrice: proposedPrice,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      maxShippers: maxShippers,
      joinedShippers: joinedShippers ?? this.joinedShippers,
      status: status ?? this.status,
    );
  }
}

class ShipperInTrip {
  final String shipperId;
  final String shipperName;
  final String shipperPhone;
  final String cargoType; // Loại hàng
  final String cargoWeight; // Khối lượng
  final String price; // Giá nhân khác nhau cho shipper này
  final DateTime joinedAt;
  final String status; // 'pending' | 'confirmed' | 'picked' | 'delivered'

  ShipperInTrip({
    required this.shipperId,
    required this.shipperName,
    required this.shipperPhone,
    required this.cargoType,
    required this.cargoWeight,
    required this.price,
    required this.status,
  }) : joinedAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'shipperId': shipperId,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'cargoType': cargoType,
      'cargoWeight': cargoWeight,
      'price': price,
      'joinedAt': joinedAt.toIso8601String(),
      'status': status,
    };
  }

  factory ShipperInTrip.fromMap(Map<String, dynamic> map) {
    return ShipperInTrip(
      shipperId: map['shipperId'] as String,
      shipperName: map['shipperName'] as String,
      shipperPhone: map['shipperPhone'] as String,
      cargoType: map['cargoType'] as String,
      cargoWeight: map['cargoWeight'] as String,
      price: map['price'] as String,
      status: map['status'] as String? ?? 'pending',
    );
  }
}
