import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final instance = FirebaseService._();
  FirebaseService._();

  final _db = FirebaseDatabase.instance.ref();

  // ========== BIDDING ORDERS ==========

  /// Thêm bidding order từ shipper
  Future<void> addBiddingOrder(Map<String, dynamic> order) async {
    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      await _db.child('bidding_orders').child(orderId).set({
        'id': orderId,
        'from': order['from'],
        'to': order['to'],
        'goods': order['goods'],
        'weight': order['weight'],
        'price': order['price'],
        'pickup': order['pickup'],
        'deliver': order['deliver'],
        'shipperName': order['shipperName'],
        'shipperPhone': order['shipperPhone'] ?? '',
        'bids': {},
        'status': 'available', // available, waiting, accepted, completed
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firebase: Bidding order added: $orderId');
    } catch (e) {
      debugPrint('❌ Error adding bidding order: $e');
      rethrow;
    }
  }

  /// Lấy tất cả bidding orders (realtime stream)
  Stream<List<Map<String, dynamic>>> getBiddingOrdersStream() {
    return _db.child('bidding_orders').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final data = event.snapshot.value as Map;
        return data.entries.map((e) {
          final order = Map<String, dynamic>.from(e.value as Map);
          return order;
        }).toList();
      } catch (e) {
        debugPrint('❌ Error parsing bidding orders: $e');
        return [];
      }
    });
  }

  /// Lấy bidding orders theo shipper
  Stream<List<Map<String, dynamic>>> getMyBiddingOrdersStream(
      String shipperPhone) {
    return _db.child('bidding_orders').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final data = event.snapshot.value as Map;
        return data.entries
            .map((e) {
              final order = Map<String, dynamic>.from(e.value as Map);
              return order;
            })
            .where((order) => order['shipperPhone'] == shipperPhone)
            .toList();
      } catch (e) {
        debugPrint('❌ Error parsing my bidding orders: $e');
        return [];
      }
    });
  }

  /// Thêm bid vào bidding order
  Future<void> addBidToOrder(
    String orderId,
    Map<String, dynamic> bid,
  ) async {
    try {
      final bidId = DateTime.now().millisecondsSinceEpoch.toString();
      await _db
          .child('bidding_orders')
          .child(orderId)
          .child('bids')
          .child(bidId)
          .set({
        'id': bidId,
        'driverName': bid['driverName'],
        'driverPhone': bid['driverPhone'],
        'driverId': bid['driverId'],
        'bidPrice': bid['bidPrice'],
        'status': 'pending', // pending, accepted, rejected, completed
        'bidTime': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firebase: Bid added to order: $orderId');
    } catch (e) {
      debugPrint('❌ Error adding bid: $e');
      rethrow;
    }
  }

  /// Cập nhật status bidding order
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db
          .child('bidding_orders')
          .child(orderId)
          .update({'status': status});
      debugPrint('✅ Firebase: Order status updated: $orderId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      rethrow;
    }
  }

  // ========== EMPTY TRIPS ==========

  /// Tạo empty trip từ driver
  Future<void> addEmptyTrip(Map<String, dynamic> trip) async {
    try {
      final tripId = trip['id'];
      await _db.child('empty_trips').child(tripId).set({
        'id': tripId,
        'driverId': trip['driverId'],
        'driverName': trip['driverName'],
        'driverPhone': trip['driverPhone'],
        'from': trip['from'],
        'to': trip['to'],
        'containerType': trip['containerType'],
        'capacity': trip['capacity'],
        'proposedPrice': trip['proposedPrice'],
        'pickupTime': trip['pickupTime'],
        'deliveryTime': trip['deliveryTime'],
        'maxShippers': trip['maxShippers'] ?? 5,
        'joinedShippers': {},
        'status': 'available', // available, full, completed
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firebase: Empty trip added: $tripId');
    } catch (e) {
      debugPrint('❌ Error adding empty trip: $e');
      rethrow;
    }
  }

  /// Lấy tất cả empty trips (realtime stream)
  Stream<List<Map<String, dynamic>>> getEmptyTripsStream() {
    return _db.child('empty_trips').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final data = event.snapshot.value as Map;
        return data.entries.map((e) {
          final trip = Map<String, dynamic>.from(e.value as Map);
          return trip;
        }).toList();
      } catch (e) {
        debugPrint('❌ Error parsing empty trips: $e');
        return [];
      }
    });
  }

  /// Lấy empty trips theo driver
  Stream<List<Map<String, dynamic>>> getMyEmptyTripsStream(
      String driverPhone) {
    return _db.child('empty_trips').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final data = event.snapshot.value as Map;
        return data.entries
            .map((e) {
              final trip = Map<String, dynamic>.from(e.value as Map);
              return trip;
            })
            .where((trip) => trip['driverPhone'] == driverPhone)
            .toList();
      } catch (e) {
        debugPrint('❌ Error parsing my empty trips: $e');
        return [];
      }
    });
  }

  /// Shipper join empty trip
  Future<void> addShipperToTrip(
    String tripId,
    Map<String, dynamic> shipper,
  ) async {
    try {
      final shipperId = shipper['shipperId'];
      await _db
          .child('empty_trips')
          .child(tripId)
          .child('joinedShippers')
          .child(shipperId)
          .set({
        'shipperId': shipperId,
        'shipperName': shipper['shipperName'],
        'shipperPhone': shipper['shipperPhone'],
        'joinedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firebase: Shipper joined trip: $tripId');
    } catch (e) {
      debugPrint('❌ Error adding shipper to trip: $e');
      rethrow;
    }
  }

  /// Remove shipper khỏi trip
  Future<void> removeShipperFromTrip(String tripId, String shipperId) async {
    try {
      await _db
          .child('empty_trips')
          .child(tripId)
          .child('joinedShippers')
          .child(shipperId)
          .remove();
      debugPrint('✅ Firebase: Shipper removed from trip: $tripId');
    } catch (e) {
      debugPrint('❌ Error removing shipper from trip: $e');
      rethrow;
    }
  }

  /// Cập nhật status empty trip
  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      await _db
          .child('empty_trips')
          .child(tripId)
          .update({'status': status});
      debugPrint('✅ Firebase: Trip status updated: $tripId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating trip status: $e');
      rethrow;
    }
  }

  // ========== NOTIFICATIONS (Optional) ==========

  /// Thêm notification
  Future<void> addNotification(
    String userId,
    Map<String, dynamic> notification,
  ) async {
    try {
      final notifId = DateTime.now().millisecondsSinceEpoch.toString();
      await _db
          .child('notifications')
          .child(userId)
          .child(notifId)
          .set({
        'id': notifId,
        'type': notification['type'], // bid, joined, accepted, etc
        'title': notification['title'],
        'message': notification['message'],
        'data': notification['data'] ?? {},
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firebase: Notification added for user: $userId');
    } catch (e) {
      debugPrint('❌ Error adding notification: $e');
      rethrow;
    }
  }

  /// Lấy notifications theo user (realtime)
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _db.child('notifications').child(userId).onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final data = event.snapshot.value as Map;
        return data.entries.map((e) {
          final notif = Map<String, dynamic>.from(e.value as Map);
          return notif;
        }).toList();
      } catch (e) {
        debugPrint('❌ Error parsing notifications: $e');
        return [];
      }
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _db
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }
}
