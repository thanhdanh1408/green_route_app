// lib/features/shipper/models/order_model.dart
enum OrderStatus { pending, processing, delivering, completed, failed }

class Order {
  final String id;
  final String from;
  final String to;
  final String goods;
  final String weight;
  final String price;
  final String pickupTime;
  final String deliverTime;
  final DateTime postedAt;
  OrderStatus status;

  Order({
    required this.id,
    required this.from,
    required this.to,
    required this.goods,
    required this.weight,
    required this.price,
    required this.pickupTime,
    required this.deliverTime,
    required this.postedAt,
    this.status = OrderStatus.pending,
  });
}