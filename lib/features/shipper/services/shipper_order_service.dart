import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShipperOrderService {
  static const String _waitingOrdersKey = 'shipper_waiting_orders';
  
  // Lấy các đơn đang chờ (chờ chuyến đầy)
  static Future<List<Map<String, dynamic>>> getWaitingOrders(String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_waitingOrdersKey) ?? [];
    final myOrders = <Map<String, dynamic>>[];
    
    for (var orderStr in ordersJson) {
      try {
        final order = jsonDecode(orderStr) as Map<String, dynamic>;
        if (order['shipperId'] == shipperId && order['status'] == 'waiting') {
          myOrders.add(order);
        }
      } catch (e) {
        // Skip invalid orders
      }
    }
    
    return myOrders;
  }
  
  // Lấy các đơn đang giao (chuyến đã đầy, đang vận chuyển)
  static Future<List<Map<String, dynamic>>> getDeliveringOrders(String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_waitingOrdersKey) ?? [];
    final myOrders = <Map<String, dynamic>>[];
    
    for (var orderStr in ordersJson) {
      try {
        final order = jsonDecode(orderStr) as Map<String, dynamic>;
        if (order['shipperId'] == shipperId && order['status'] == 'delivering') {
          myOrders.add(order);
        }
      } catch (e) {
        // Skip invalid orders
      }
    }
    
    return myOrders;
  }
  
  // Lấy tất cả orders của shipper
  static Future<List<Map<String, dynamic>>> getAllOrders(String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_waitingOrdersKey) ?? [];
    final myOrders = <Map<String, dynamic>>[];
    
    for (var orderStr in ordersJson) {
      try {
        final order = jsonDecode(orderStr) as Map<String, dynamic>;
        if (order['shipperId'] == shipperId) {
          myOrders.add(order);
        }
      } catch (e) {
        // Skip invalid orders
      }
    }
    
    return myOrders;
  }
}
