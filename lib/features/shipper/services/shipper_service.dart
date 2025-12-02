// lib/features/shipper/services/shipper_service.dart
import '../models/order.dart';

class ShipperService {
  ShipperService._();
  static final instance = ShipperService._();

  final List<Order> _activeOrders = [];     // Đang xử lý + Đang giao
  final List<Order> _historyOrders = [];    // Hoàn thành + Thất bại

  List<Order> get activeOrders => List.unmodifiable(_activeOrders);
  List<Order> get historyOrders => List.unmodifiable(_historyOrders);

  void addPendingOrder(Map<String, dynamic> data) {
    final order = Order(
      id: 'OR${DateTime.now().millisecondsSinceEpoch}',
      from: data['from'],
      to: data['to'],
      goods: data['goods'],
      weight: data['weight'],
      price: data['price'],
      pickupTime: data['pickup'],
      deliverTime: data['deliver'],
      postedAt: DateTime.now(),
      status: OrderStatus.processing, // Đang xử lý
    );
    _activeOrders.add(order);
  }

  // Khi tài xế nhận đơn → chuyển sang Đang giao
  void acceptOrder(String orderId) {
    final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      _activeOrders[orderIndex].status = OrderStatus.delivering;
    }
  }

  // Khi tài xế bấm hoàn thành/thất bại → chuyển sang lịch sử
  void completeOrder(String orderId, {bool success = true}) {
    final index = _activeOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _activeOrders.removeAt(index);
      order.status = success ? OrderStatus.completed : OrderStatus.failed;
      _historyOrders.add(order);
    }
  }
}