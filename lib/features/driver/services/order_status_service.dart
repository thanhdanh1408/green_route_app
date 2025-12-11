import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/order_pool_service.dart';
import '../models/order_model.dart';

class OrderStatusService {
  static const String _driverBidsKey = 'driver_bids';
  static const String _shipperReceivedBidsKey = 'shipper_received_bids';

  static final _orderStreamController = StreamController<void>.broadcast();
  static Stream<void> get orderStream => _orderStreamController.stream;

  static Future<void> driverSendBid(PooledOrder order, String bidPrice) async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('user_phone') ?? 'unknown_driver';
    final driverName = prefs.getString('name') ?? 'Tài xế ẩn danh';

    final bid = {
      'orderId': order.id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverId, // Using phone as ID and phone
      'bidPrice': bidPrice,
      'status': 'pending',
      'from': order.from,
      'to': order.to,
      'goods': order.goods,
      'weight': order.weight,
    };

    final shipperBids = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    final isDuplicate = shipperBids.any((s) {
      final decoded = jsonDecode(s);
      return decoded['orderId'] == order.id && decoded['driverId'] == driverId;
    });

    if (!isDuplicate) {
      shipperBids.add(jsonEncode(bid));
      await prefs.setStringList(_shipperReceivedBidsKey, shipperBids);
    }

    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    if (!driverBids.any((s) => jsonDecode(s)['orderId'] == order.id)) {
       driverBids.add(jsonEncode(bid));
       await prefs.setStringList(_driverBidsKey, driverBids);
    }

    _orderStreamController.add(null);
  }

  static Future<void> shipperAcceptBid(String orderId, String driverId) async {
    final prefs = await SharedPreferences.getInstance();

    final shipperBids = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    final updatedShipperBids = shipperBids.map((s) {
      final bid = jsonDecode(s);
      if (bid['orderId'] == orderId && bid['driverId'] == driverId) {
        bid['status'] = 'accepted';
      }
      return jsonEncode(bid);
    }).toList();
    await prefs.setStringList(_shipperReceivedBidsKey, updatedShipperBids);

    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
     final updatedDriverBids = driverBids.map((s) {
      final bid = jsonDecode(s);
      if (bid['orderId'] == orderId && bid['driverId'] == driverId) {
        bid['status'] = 'accepted';
      }
      return jsonEncode(bid);
    }).toList();
    await prefs.setStringList(_driverBidsKey, updatedDriverBids);

    _orderStreamController.add(null);
  }

  static Future<List<OrderModel>> getBiddingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    final orders = <OrderModel>[];
    for (final s in driverBids) {
      final bid = jsonDecode(s);
      if (bid['status'] == 'pending') {
        orders.add(OrderModel.fromBid(bid));
      }
    }
    return orders;
  }

  static Future<List<OrderModel>> getDeliveringOrders() async {
     final prefs = await SharedPreferences.getInstance();
    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    final orders = <OrderModel>[];
    for (final s in driverBids) {
      final bid = jsonDecode(s);
      if (bid['status'] == 'accepted') {
        orders.add(OrderModel.fromBid(bid));
      }
    }
    return orders;
  }

  static Future<List<OrderModel>> getHistoryOrders() async {
    return [];
  }

  static Future<List<Map<String, dynamic>>> getShipperBids() async {
    final prefs = await SharedPreferences.getInstance();
    final bidsJson = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    final pendingBids = <Map<String, dynamic>>[];
    for (final jsonStr in bidsJson) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (decoded['status'] == 'pending') {
          pendingBids.add(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding bid: $e');
      }
    }
    return pendingBids;
  }

  static Future<List<OrderModel>> getWaitingOrders() async {
    return getBiddingOrders();
  }

  static Future<List<OrderModel>> getAcceptedOrders() async {
    return getDeliveringOrders();
  }

  static Future<List<OrderModel>> getCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    final orders = <OrderModel>[];
    for (final s in driverBids) {
      final bid = jsonDecode(s);
      if (bid['status'] == 'completed') {
        orders.add(OrderModel.fromBid(bid));
      }
    }
    return orders;
  }

  static Future<void> addWaitingOrder(OrderModel order, String bidPrice) async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('user_phone') ?? 'unknown_driver';
    final driverName = prefs.getString('name') ?? 'Tài xế ẩn danh';

    final bid = {
      'orderId': order.id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverId,
      'bidPrice': bidPrice,
      'status': 'pending',
      'from': order.from,
      'to': order.to,
      'goods': order.goods,
      'weight': order.weight,
    };

    final shipperBids = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    // Check duplication
    final isDuplicate = shipperBids.any((s) {
      final decoded = jsonDecode(s);
      return decoded['orderId'] == order.id && decoded['driverId'] == driverId;
    });

    if (!isDuplicate) {
      shipperBids.add(jsonEncode(bid));
      await prefs.setStringList(_shipperReceivedBidsKey, shipperBids);
    }

    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    if (!driverBids.any((s) => jsonDecode(s)['orderId'] == order.id)) {
       driverBids.add(jsonEncode(bid));
       await prefs.setStringList(_driverBidsKey, driverBids);
    }

    _orderStreamController.add(null);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverBidsKey);
    await prefs.remove(_shipperReceivedBidsKey);
    _orderStreamController.add(null);
  }
}
