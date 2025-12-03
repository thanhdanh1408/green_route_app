// lib/features/driver/services/order_status_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/order_model.dart';

class OrderStatusService {
  static const String _driverOrdersKey = 'driver_orders'; // Danh sách orders của driver với bidStatus
  static const String _shipper_bidsKey = 'shipper_received_bids'; // Shipper xem bids
  static const String _completedOrdersKey = 'completed_orders'; // Lịch sử

  // ========== QUẢN LÝ ORDERS CỦA DRIVER ==========

  // THÊM/UPDATE ĐƠN VÀO DANH SÁCH DRIVER
  static Future<void> addWaitingOrder(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersList = prefs.getStringList(_driverOrdersKey) ?? [];
    
    final existingIndex = ordersList.indexWhere((e) => OrderModel.fromJson(e).id == order.id);
    
    if (existingIndex != -1) {
      final existingOrder = OrderModel.fromJson(ordersList[existingIndex]);
      // Nếu đã bid/accepted/completed rồi, không cho bid lại
      if (existingOrder.bidStatus != 'available') {
        debugPrint('⚠️ Bạn đã gửi giá đấu thầu cho đơn này rồi!');
        return;
      }
    }

    // Update order với bidStatus = 'waiting'
    final updatedOrder = order.copyWith(bidStatus: 'waiting');
    if (existingIndex != -1) {
      ordersList[existingIndex] = updatedOrder.toJson();
    } else {
      ordersList.add(updatedOrder.toJson());
    }
    
    await prefs.setStringList(_driverOrdersKey, ordersList);
    await _notifyShipperAboutBid(order);
  }

  // CHUYỂN TRẠNG THÁI WAITING -> ACCEPTED (khi shipper accept bid)
  static Future<void> acceptOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersList = prefs.getStringList(_driverOrdersKey) ?? [];
    
    final index = ordersList.indexWhere((e) => OrderModel.fromJson(e).id == orderId);
    if (index != -1) {
      final order = OrderModel.fromJson(ordersList[index]);
      final updatedOrder = order.copyWith(bidStatus: 'accepted');
      ordersList[index] = updatedOrder.toJson();
      await prefs.setStringList(_driverOrdersKey, ordersList);
    }
  }

  // CHUYỂN TRẠNG THÁI ACCEPTED -> COMPLETED (khi hoàn tất đơn)
  static Future<void> completeOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersList = prefs.getStringList(_driverOrdersKey) ?? [];
    
    final index = ordersList.indexWhere((e) => OrderModel.fromJson(e).id == orderId);
    if (index != -1) {
      final order = OrderModel.fromJson(ordersList[index]);
      
      // Chuyển qua completed_orders với trạng thái 'transporting'
      final completedOrder = order.copyWith(bidStatus: 'transporting');
      final completedList = prefs.getStringList(_completedOrdersKey) ?? [];
      completedList.add(completedOrder.toJson());
      
      // Xóa khỏi driver_orders
      ordersList.removeAt(index);
      
      await prefs.setStringList(_driverOrdersKey, ordersList);
      await prefs.setStringList(_completedOrdersKey, completedList);
    }
  }

  // LẤY TẤT CẢ ORDERS CỦA DRIVER (tất cả trạng thái)
  static Future<List<OrderModel>> getAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_driverOrdersKey) ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // LẤY DANH SÁCH WAITING ORDERS (theo trạng thái)
  static Future<List<OrderModel>> getWaitingOrders() async {
    final all = await getAllOrders();
    return all.where((o) => o.bidStatus == 'waiting').toList();
  }

  // LẤY DANH SÁCH ACCEPTED ORDERS
  static Future<List<OrderModel>> getAcceptedOrders() async {
    final all = await getAllOrders();
    return all.where((o) => o.bidStatus == 'accepted').toList();
  }

  // LẤY LỊCH SỬ (completed orders)
  static Future<List<OrderModel>> getCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_completedOrdersKey) ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // ========== THÔNG BÁO SHIPPER ==========

  static Future<void> _notifyShipperAboutBid(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    
    final bidEntry = {
      'orderId': order.id,
      'shipperName': order.shipperName,
      'shipperPhone': order.shipperPhone,
      'driverId': '0987654321', // Mock
      'driverName': 'Tài xế Nguyễn Văn Nam', // Mock
      'bidPrice': order.price,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    final existingBids = prefs.getStringList(_shipper_bidsKey) ?? [];
    final bidJson = jsonEncode(bidEntry);
    if (!existingBids.contains(bidJson)) {
      existingBids.add(bidJson);
      await prefs.setStringList(_shipper_bidsKey, existingBids);
    }

    debugPrint('Thông báo shipper: ${order.shipperName} có bid mới');
  }

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

  // XÓA TẤT CẢ DỮ LIỆU
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverOrdersKey);
    await prefs.remove(_completedOrdersKey);
    await prefs.remove(_shipper_bidsKey);
  }
}

