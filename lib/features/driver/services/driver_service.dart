// lib/features/driver/services/driver_service.dart
import '../models/order_model.dart';
import '../../../core/services/order_pool_service.dart';

class DriverService {
  static final DriverService _instance = DriverService._();
  factory DriverService() => _instance;
  DriverService._();

  Future<List<OrderModel>> getAvailableOrders() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Giả lập API
    
    // Lấy đơn từ OrderPoolService (chủ hàng đã đăng)
    final pooledOrders = OrderPoolService.instance.availableOrders
        .where((o) => o.type == OrderType.normal) // Chỉ lấy đơn bình thường (không phải ghép hàng)
        .toList();

    // Chuyển đổi PooledOrder → OrderModel
    return pooledOrders.map((pooled) {
      return OrderModel(
        id: pooled.id,
        from: pooled.from,
        to: pooled.to,
        fromDetail: pooled.from,
        toDetail: pooled.to,
        weight: pooled.weight,
        price: pooled.proposedPrice,
        receiveDate: pooled.pickupTime,
        deliverDate: pooled.deliverTime,
        shipperName: pooled.shipperName,
        shipperPhone: '', // Không có thông tin điện thoại ở PooledOrder
      );
    }).toList();
  }
}
