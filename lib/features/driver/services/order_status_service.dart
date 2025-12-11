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
      'driverPhone': driverId,
      'bidPrice': bidPrice,
      'status': 'pending',
      'from': order.from,
      'to': order.to,
      'goods': order.goods,
      'weight': order.weight,
      // Thêm thông tin shipper đầy đủ
      'shipperId': order.shipperPhone ?? '',
      'shipperName': order.shipperName,
      'shipperPhone': order.shipperPhone ?? '',
      'fromDetail': order.fromDetail ?? '',
      'toDetail': order.toDetail ?? '',
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
    debugPrint('👍 Shipper accepting bid: orderId=$orderId, driverId=$driverId');
    final prefs = await SharedPreferences.getInstance();

    final shipperBids = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    debugPrint('  - Total shipper bids before: ${shipperBids.length}');
    
    final updatedShipperBids = shipperBids.map((s) {
      final bid = jsonDecode(s);
      if (bid['orderId'] == orderId && bid['driverId'] == driverId) {
        debugPrint('  ✅ Found matching bid in shipper_received_bids, updating to accepted');
        debugPrint('     shipperId: ${bid['shipperId']}, shipperPhone: ${bid['shipperPhone']}');
        bid['status'] = 'accepted';
      }
      return jsonEncode(bid);
    }).toList();
    await prefs.setStringList(_shipperReceivedBidsKey, updatedShipperBids);

    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    debugPrint('  - Total driver bids before: ${driverBids.length}');
    
     final updatedDriverBids = driverBids.map((s) {
      final bid = jsonDecode(s);
      if (bid['orderId'] == orderId && bid['driverId'] == driverId) {
        debugPrint('  ✅ Found matching bid in driver_bids, updating to accepted');
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
      // Thêm thông tin shipper đầy đủ
      'shipperId': order.shipperPhone ?? '',
      'shipperName': order.shipperName ?? 'Không có thông tin',
      'shipperPhone': order.shipperPhone ?? '',
      'fromDetail': order.fromDetail,
      'toDetail': order.toDetail,
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

  // Lấy các đơn đã accepted HOẶC completed của shipper
  static Future<List<Map<String, dynamic>>> getShipperAcceptedOrders(String shipperId) async {
    debugPrint('🔍 getShipperAcceptedOrders for shipperId: $shipperId');
    final prefs = await SharedPreferences.getInstance();
    final bidsJson = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    debugPrint('  - Total bids in storage: ${bidsJson.length}');
    
    final acceptedOrders = <Map<String, dynamic>>[];
    
    for (final jsonStr in bidsJson) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        // Check cả shipperId và shipperPhone vì có thể sử dụng cả 2
        final bidShipperId = decoded['shipperId'] ?? '';
        final bidShipperPhone = decoded['shipperPhone'] ?? '';
        final bidStatus = decoded['status'] ?? '';
        
        debugPrint('  - Bid: orderId=${decoded['orderId']}, status=$bidStatus, shipperId=$bidShipperId, shipperPhone=$bidShipperPhone');
        
        // BỔ SUNG: Lấy cả 'accepted' VÀ 'completed' để shipper thấy được trạng thái hoàn thành
        if ((decoded['status'] == 'accepted' || decoded['status'] == 'completed') && 
            (bidShipperId == shipperId || bidShipperPhone == shipperId)) {
          debugPrint('    ✅ MATCHED! Adding to orders (status: ${decoded['status']})');
          acceptedOrders.add(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding bid: $e');
      }
    }
    
    debugPrint('  - Total orders found: ${acceptedOrders.length}');
    return acceptedOrders;
  }

  // Complete regular order - mark as completed
  static Future<void> completeOrder(String orderId) async {
    debugPrint('✅ Completing regular order: $orderId');
    final prefs = await SharedPreferences.getInstance();
    final completedAt = DateTime.now().toIso8601String();
    
    // Update driver_bids
    final driverBids = prefs.getStringList(_driverBidsKey) ?? [];
    debugPrint('  📋 Checking ${driverBids.length} orders in driver_bids');
    
    bool foundInDriverBids = false;
    final updatedDriverBids = driverBids.map((s) {
      final bid = jsonDecode(s);
      final bidOrderId = bid['orderId'];
      debugPrint('    - Checking orderId: $bidOrderId (looking for: $orderId)');
      
      if (bidOrderId == orderId) {
        debugPrint('    ✓ MATCH FOUND in driver_bids! Marking as completed');
        bid['status'] = 'completed';
        bid['completedAt'] = completedAt; // Thêm timestamp
        foundInDriverBids = true;
      }
      return jsonEncode(bid);
    }).toList();
    
    if (!foundInDriverBids) {
      debugPrint('    ⚠️ Order $orderId NOT FOUND in driver_bids!');
    }
    
    await prefs.setStringList(_driverBidsKey, updatedDriverBids);

    // Update shipper_received_bids
    final shipperBids = prefs.getStringList(_shipperReceivedBidsKey) ?? [];
    debugPrint('  📋 Checking ${shipperBids.length} orders in shipper_received_bids');
    
    bool foundInShipperBids = false;
    final updatedShipperBids = shipperBids.map((s) {
      final bid = jsonDecode(s);
      final bidOrderId = bid['orderId'];
      debugPrint('    - Checking orderId: $bidOrderId (looking for: $orderId)');
      
      if (bidOrderId == orderId) {
        debugPrint('    ✓ MATCH FOUND in shipper_received_bids! Marking as completed');
        bid['status'] = 'completed';
        bid['completedAt'] = completedAt; // Thêm timestamp
        foundInShipperBids = true;
      }
      return jsonEncode(bid);
    }).toList();
    
    if (!foundInShipperBids) {
      debugPrint('    ⚠️ Order $orderId NOT FOUND in shipper_received_bids!');
    }
    
    await prefs.setStringList(_shipperReceivedBidsKey, updatedShipperBids);

    if (foundInDriverBids || foundInShipperBids) {
      debugPrint('  ✅ Order $orderId marked as completed (driver: $foundInDriverBids, shipper: $foundInShipperBids)');
    } else {
      debugPrint('  ❌ Order $orderId was NOT FOUND in any storage!');
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
