// lib/features/driver/services/order_status_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/order_model.dart';

class OrderStatusService {
  static const String _waitingOrdersKey = 'waiting_orders';
  static const String _acceptedOrdersKey = 'accepted_orders';
  static const String _completedOrdersKey = 'completed_orders';
  static const String _shipper_bidsKey = 'shipper_received_bids'; // ← NEW: Shipper xem bids

  // THÊM ĐƠN VÀO TRẠNG THÁI ĐANG CHỜ + THÔNG BÁO SHIPPER
  static Future<void> addWaitingOrder(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    final existingList = prefs.getStringList(_waitingOrdersKey) ?? [];
    if (!existingList.contains(order.toJson())) {
      existingList.add(order.toJson());
      await prefs.setStringList(_waitingOrdersKey, existingList);
    }

    // THÊM BID VÀO DANH SÁCH CHO SHIPPER XEM
    await _notifyShipperAboutBid(order);
  }

  // THÔNG BÁO SHIPPER CÓ BID MỚI
  static Future<void> _notifyShipperAboutBid(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Tạo bid entry cho shipper
    final bidEntry = {
      'orderId': order.id,
      'shipperName': order.shipperName,
      'shipperPhone': order.shipperPhone,
      'driverId': '0987654321', // Mock driver ID
      'driverName': 'Tài xế Nguyễn Văn Nam', // Mock driver name
      'bidPrice': order.price,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending', // Chờ shipper quyết định
    };

    final existingBids = prefs.getStringList(_shipper_bidsKey) ?? [];
    // Kiểm tra không trùng
    final bidJson = jsonEncode(bidEntry);
    if (!existingBids.contains(bidJson)) {
      existingBids.add(bidJson);
      await prefs.setStringList(_shipper_bidsKey, existingBids);
    }

    debugPrint('Thông báo shipper: ${order.shipperName} có bid từ ${bidEntry['driverName']}');
  }

  // LẤY DANH SÁCH BID CHO SHIPPER
  static Future<List<Map<String, dynamic>>> getShipperBids() async {
    final prefs = await SharedPreferences.getInstance();
    final bidsJson = prefs.getStringList(_shipper_bidsKey) ?? [];
    final result = <Map<String, dynamic>>[];
    for (final jsonStr in bidsJson) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<dynamic, dynamic>;
        result.add(decoded.cast<String, dynamic>());
      } catch (e) {
        debugPrint('Error decoding bid: $e');
      }
    }
    return result;
  }

  // LẤY DANH SÁCH ĐƠN ĐANG CHỜ
  static Future<List<OrderModel>> getWaitingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_waitingOrdersKey) ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // CHUYỂN ĐƠN TỪ ĐANG CHỜ SANG CHẤP NHẬN (TRÚNG THẦU)
  static Future<void> acceptOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Lấy đơn từ waiting_orders
    final waitingList = prefs.getStringList(_waitingOrdersKey) ?? [];
    final orderJson = waitingList.firstWhere(
      (e) => OrderModel.fromJson(e).id == orderId,
      orElse: () => '',
    );

    if (orderJson.isNotEmpty) {
      // Xóa khỏi waiting
      waitingList.remove(orderJson);
      await prefs.setStringList(_waitingOrdersKey, waitingList);

      // Thêm vào accepted
      final acceptedList = prefs.getStringList(_acceptedOrdersKey) ?? [];
      acceptedList.add(orderJson);
      await prefs.setStringList(_acceptedOrdersKey, acceptedList);
    }
  }

  // LẤY DANH SÁCH ĐƠN ĐÃ CHẤP NHẬN
  static Future<List<OrderModel>> getAcceptedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_acceptedOrdersKey) ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // CHUYỂN ĐƠN TỪ CHẤP NHẬN SANG HOÀN TẤT
  static Future<void> completeOrder(String orderId, {String? notes}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Lấy đơn từ accepted_orders
    final acceptedList = prefs.getStringList(_acceptedOrdersKey) ?? [];
    final orderJson = acceptedList.firstWhere(
      (e) => OrderModel.fromJson(e).id == orderId,
      orElse: () => '',
    );

    if (orderJson.isNotEmpty) {
      // Xóa khỏi accepted
      acceptedList.remove(orderJson);
      await prefs.setStringList(_acceptedOrdersKey, acceptedList);

      // Thêm vào completed
      final completedList = prefs.getStringList(_completedOrdersKey) ?? [];
      completedList.add(orderJson);
      await prefs.setStringList(_completedOrdersKey, completedList);
    }
  }

  // LẤY DANH SÁCH ĐƠN ĐÃ HOÀN TẤT
  static Future<List<OrderModel>> getCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_completedOrdersKey) ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // XÓA ĐƠN TỪ ĐANG CHỜ (TỪ CHỐI)
  static Future<void> rejectWaitingOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final waitingList = prefs.getStringList(_waitingOrdersKey) ?? [];
    waitingList.removeWhere((e) => OrderModel.fromJson(e).id == orderId);
    await prefs.setStringList(_waitingOrdersKey, waitingList);
  }

  // XÓA TẤT CẢ DỮ LIỆU (ĐĂNG XUẤT)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_waitingOrdersKey);
    await prefs.remove(_acceptedOrdersKey);
    await prefs.remove(_completedOrdersKey);
    await prefs.remove(_shipper_bidsKey);
  }
}

