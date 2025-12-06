// lib/core/services/global_data_server.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Global Shared Storage - sync data giữa Web & Android qua SharedPreferences
class GlobalDataServer {
  GlobalDataServer._();
  static final instance = GlobalDataServer._();

  static const String _biddingOrdersKey = 'global_bidding_orders';
  static const String _emptyTripsKey = 'global_empty_trips';

  // Bidding Orders
  Future<void> addBiddingOrder(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_biddingOrdersKey) ?? [];
    
    ordersJson.add(jsonEncode(order));
    await prefs.setStringList(_biddingOrdersKey, ordersJson);
    
    debugPrint('✅ Added bidding order: ${order['id']}');
    _printStatus(ordersJson.length, (prefs.getStringList(_emptyTripsKey) ?? []).length);
  }

  Future<List<Map<String, dynamic>>> getBiddingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_biddingOrdersKey) ?? [];
    
    return ordersJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> addBidToOrder(String orderId, Map<String, dynamic> bid) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_biddingOrdersKey) ?? [];
    
    final idx = ordersJson.indexWhere((json) {
      final order = jsonDecode(json) as Map<String, dynamic>;
      return order['id'] == orderId;
    });
    
    if (idx != -1) {
      final order = jsonDecode(ordersJson[idx]) as Map<String, dynamic>;
      final bids = (order['bids'] as List?) ?? [];
      bids.add(bid);
      order['bids'] = bids;
      
      ordersJson[idx] = jsonEncode(order);
      await prefs.setStringList(_biddingOrdersKey, ordersJson);
      
      debugPrint('✅ Added bid to order: $orderId');
    }
  }

  Future<List<Map<String, dynamic>>> getBidsForOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getStringList(_biddingOrdersKey) ?? [];
    
    for (final json in ordersJson) {
      final order = jsonDecode(json) as Map<String, dynamic>;
      if (order['id'] == orderId) {
        final bids = (order['bids'] as List?) ?? [];
        return bids.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  // Empty Trips
  Future<void> addEmptyTrip(Map<String, dynamic> trip) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    tripsJson.add(jsonEncode(trip));
    await prefs.setStringList(_emptyTripsKey, tripsJson);
    
    debugPrint('✅ Added empty trip: ${trip['id']}');
    _printStatus((prefs.getStringList(_biddingOrdersKey) ?? []).length, tripsJson.length);
  }

  Future<List<Map<String, dynamic>>> getEmptyTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    return tripsJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> addShipperToTrip(String tripId, Map<String, dynamic> shipper) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    final idx = tripsJson.indexWhere((json) {
      final trip = jsonDecode(json) as Map<String, dynamic>;
      return trip['id'] == tripId;
    });
    
    if (idx != -1) {
      final trip = jsonDecode(tripsJson[idx]) as Map<String, dynamic>;
      final shippers = (trip['joinedShippers'] as List?) ?? [];
      shippers.add(shipper);
      trip['joinedShippers'] = shippers;
      
      tripsJson[idx] = jsonEncode(trip);
      await prefs.setStringList(_emptyTripsKey, tripsJson);
      
      debugPrint('✅ Shipper joined trip: $tripId');
    }
  }

  void _printStatus(int orders, int trips) {
    debugPrint('📊 Global Server Status:');
    debugPrint('  - Bidding Orders: $orders');
    debugPrint('  - Empty Trips: $trips');
  }
}
