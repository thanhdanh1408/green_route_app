// lib/features/shipper/services/booking_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class BookingService {
  static const _bookingRequestsKey = 'booking_requests';
  
  // Tạo booking request  
  static Future<String> createBookingRequest({
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String shipperId,
    required String shipperName,
    required String shipperPhone,
    required String from,
    required String to,
    required String fromDetail,
    required String toDetail,
    required String goods,
    required String weight,
    required String price,
    required String pickupTime,
    required String deliverTime,
    required bool hasInsurance,
    required String insuranceFee,
    required String totalPrice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = const Uuid().v4();
    
    final booking = {
      'id': bookingId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'shipperId': shipperId,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'from': from,
      'to': to,
      'fromDetail': fromDetail,
      'toDetail': toDetail,
      'goods': goods,
      'weight': weight,
      'price': price,
      'pickupTime': pickupTime,
      'deliverTime': deliverTime,
      'hasInsurance': hasInsurance,
      'insuranceFee': insuranceFee,
      'totalPrice': totalPrice,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final bookings = prefs.getStringList(_bookingRequestsKey) ?? [];
    bookings.add(jsonEncode(booking));
    await prefs.setStringList(_bookingRequestsKey, bookings);
    
    // ALSO ADD TO shipper_received_bids so shipper can see it in their orders as pending
    const shipperBidsKey = 'shipper_received_bids';
    final shipperBids = prefs.getStringList(shipperBidsKey) ?? [];
    final bid = {
      'orderId': bookingId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'bidPrice': totalPrice,
      'status': 'pending', // Pending until driver accepts
      'from': from,
      'to': to,
      'goods': goods,
      'weight': weight,
      'shipperId': shipperPhone,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'fromDetail': fromDetail,
      'toDetail': toDetail,
      'createdAt': DateTime.now().toIso8601String(),
    };
    shipperBids.add(jsonEncode(bid));
    await prefs.setStringList(shipperBidsKey, shipperBids);
    debugPrint('  ✓ Added to shipper_received_bids as pending booking');
    
    debugPrint('✅ Created booking request: $bookingId for driver $driverId');
    return bookingId;
  }
  
  // Lấy booking requests của driver
  static Future<List<Map<String, dynamic>>> getDriverBookingRequests(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList(_bookingRequestsKey) ?? [];
    
    final requests = <Map<String, dynamic>>[];
    for (final jsonStr in bookingsJson) {
      try {
        final booking = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (booking['driverId'] == driverId && booking['status'] == 'pending') {
          requests.add(booking);
        }
      } catch (e) {
        debugPrint('Error decoding booking: $e');
      }
    }
    
    debugPrint('📦 Driver $driverId has ${requests.length} pending booking requests');
    return requests;
  }
  
  // Chấp nhận booking
  static Future<void> acceptBooking(String bookingId, String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList(_bookingRequestsKey) ?? [];
    
    final updatedBookings = bookingsJson.map((jsonStr) {
      final booking = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (booking['id'] == bookingId && booking['driverId'] == driverId) {
        booking['status'] = 'accepted';
        booking['acceptedAt'] = DateTime.now().toIso8601String();
        debugPrint('✅ Accepted booking: $bookingId');
        
        // Lưu vào driver_bids để hiển thị trong history
        _saveToDriverBids(booking);
      }
      return jsonEncode(booking);
    }).toList();
    
    await prefs.setStringList(_bookingRequestsKey, updatedBookings);
  }
  
  // Từ chối booking
  static Future<void> rejectBooking(String bookingId, String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList(_bookingRequestsKey) ?? [];
    
    final updatedBookings = bookingsJson.map((jsonStr) {
      final booking = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (booking['id'] == bookingId && booking['driverId'] == driverId) {
        booking['status'] = 'rejected';
        booking['rejectedAt'] = DateTime.now().toIso8601String();
        debugPrint('❌ Rejected booking: $bookingId');
      }
      return jsonEncode(booking);
    }).toList();
    
    await prefs.setStringList(_bookingRequestsKey, updatedBookings);
  }
  
  // Lưu vào driver_bids để tái sử dụng logic history
  static Future<void> _saveToDriverBids(Map<String, dynamic> booking) async {
    final prefs = await SharedPreferences.getInstance();
    
    final bid = {
      'orderId': booking['id'],
      'driverId': booking['driverId'],
      'driverName': booking['driverName'],
      'driverPhone': booking['driverPhone'],
      'bidPrice': booking['totalPrice'],
      'status': 'accepted',
      'from': booking['from'],
      'to': booking['to'],
      'goods': booking['goods'],
      'weight': booking['weight'],
      'shipperId': booking['shipperPhone'],
      'shipperName': booking['shipperName'],
      'shipperPhone': booking['shipperPhone'],
      'fromDetail': booking['fromDetail'],
      'toDetail': booking['toDetail'],
    };
    
    // Lưu vào driver_bids - CHECK TRÙNG LẶP
    const driverBidsKey = 'driver_bids';
    final driverBids = prefs.getStringList(driverBidsKey) ?? [];
    
    // Kiểm tra xem orderId đã tồn tại chưa
    final isDuplicate = driverBids.any((jsonStr) {
      try {
        final existing = jsonDecode(jsonStr) as Map<String, dynamic>;
        return existing['orderId'] == booking['id'];
      } catch (e) {
        return false;
      }
    });
    
    if (!isDuplicate) {
      driverBids.add(jsonEncode(bid));
      await prefs.setStringList(driverBidsKey, driverBids);
      debugPrint('  ✓ Added to driver_bids');
    } else {
      debugPrint('  ⚠️ Order already exists in driver_bids, skipping');
    }
    
    // Lưu vào shipper_received_bids - CHECK TRÙNG LẶP
    const shipperBidsKey = 'shipper_received_bids';
    final shipperBids = prefs.getStringList(shipperBidsKey) ?? [];
    
    final isShipperDuplicate = shipperBids.any((jsonStr) {
      try {
        final existing = jsonDecode(jsonStr) as Map<String, dynamic>;
        return existing['orderId'] == booking['id'];
      } catch (e) {
        return false;
      }
    });
    
    if (!isShipperDuplicate) {
      shipperBids.add(jsonEncode(bid));
      await prefs.setStringList(shipperBidsKey, shipperBids);
      debugPrint('  ✓ Added to shipper_received_bids');
    } else {
      debugPrint('  ⚠️ Order already exists in shipper_received_bids, skipping');
    }
    
    debugPrint('💾 Booking save completed');
  }
  
  // Clear all bookings (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookingRequestsKey);
    debugPrint('🧹 Cleared all booking requests');
  }
}
