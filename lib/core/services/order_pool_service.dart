// lib/core/services/order_pool_service.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum OrderType { normal, matching }
enum OrderStatus { pending, accepted, rejected, delivering, completed }

class PooledOrder {
  final String id;
  final OrderType type;
  final String from;
  final String to;
  final String? fromDetail;
  final String? toDetail;
  final String goods;
  final String weight;
  final String proposedPrice;
  final String price; // Alias for proposedPrice
  final String pickupTime;
  final String deliverTime;
  final String receiveDate; // Alias for pickupTime
  final String deliverDate; // Alias for deliverTime
  final String shipperName;
  final String? shipperPhone;
  final DateTime postedAt;

  OrderStatus status;
  bool hasSeenResult; // lần đầu bấm vào chi tiết

  PooledOrder({
    required this.id,
    required this.type,
    required this.from,
    required this.to,
    this.fromDetail,
    this.toDetail,
    required this.goods,
    required this.weight,
    required this.proposedPrice,
    required this.pickupTime,
    required this.deliverTime,
    required this.shipperName,
    this.shipperPhone,
    this.status = OrderStatus.pending,
    this.hasSeenResult = false,
  }) : price = proposedPrice,
       receiveDate = pickupTime,
       deliverDate = deliverTime,
       postedAt = DateTime.now();
}

class OrderPoolService extends ChangeNotifier {
  OrderPoolService._();
  static final instance = OrderPoolService._();

  final List<PooledOrder> _orders = [];
  final ValueNotifier<List<PooledOrder>> ordersNotifier = ValueNotifier([]);

  List<PooledOrder> get availableOrders => List.unmodifiable(_orders);

  void addOrder({
    required OrderType type,
    required String from,
    required String to,
    required String goods,
    required String weight,
    required String price,
    required String pickup,
    required String deliver,
    required String shipperName,
    String? shipperPhone,
  }) {
    // FIX BUG TRÙNG: chỉ thêm nếu chưa tồn tại (dựa vào from-to-goods)
    final exists = _orders.any((o) =>
        o.from == from && o.to == to && o.goods == goods && o.type == type);

    if (exists) {
      if (kDebugMode) print('Đơn đã tồn tại, không thêm trùng!');
      return;
    }

    final order = PooledOrder(
      id: const Uuid().v4(),
      type: type,
      from: from,
      to: to,
      goods: goods,
      weight: weight,
      proposedPrice: price,
      pickupTime: pickup,
      deliverTime: deliver,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
    );

    _orders.add(order);
    ordersNotifier.value = List.from(_orders);
    notifyListeners();
  }

  void updateStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      order.status = newStatus;
      order.hasSeenResult = false; // reset để hiện popup lần đầu
      ordersNotifier.value = List.from(_orders);
      notifyListeners();
    }
  }

  void markAsSeen(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].hasSeenResult = true;
    }
  }

  // Static method for easy access
  static Future<List<PooledOrder>> getAvailableOrders() async {
    return instance.availableOrders;
  }
}