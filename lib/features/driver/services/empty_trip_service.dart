import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/empty_trip_model.dart';

class EmptyTripService {
  static const String _emptyTripsKey = 'empty_trips';

  // Stream để thông báo cho các listener khi có thay đổi
  static final _tripStreamController = StreamController<void>.broadcast();
  static Stream<void> get tripStream => _tripStreamController.stream;

  // ========== DRIVER: TẠO CHUYẾN TRỐNG ==========
  static Future<EmptyTrip> createEmptyTrip({
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String from,
    required String to,
    required String fromAddress, // Thêm
    required String toAddress, // Thêm
    required String containerType,
    required String capacity,
    required String proposedPrice,
    required DateTime pickupTime,
    required DateTime deliveryTime,
    required int maxShippers,
    LatLng? fromLatLng, // GPS coordinates
    LatLng? toLatLng, // GPS coordinates
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final trip = EmptyTrip(
      id: const Uuid().v4(),
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      from: from,
      to: to,
      fromAddress: fromAddress, // Thêm
      toAddress: toAddress, // Thêm
      containerType: containerType,
      capacity: capacity,
      proposedPrice: proposedPrice,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      maxShippers: maxShippers,
      status: 'open',
      fromLatLng: fromLatLng,
      toLatLng: toLatLng,
    );

    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    allTripsJson.add(trip.toJson());
    await prefs.setStringList(_emptyTripsKey, allTripsJson);

    debugPrint('✅ Created trip: ${trip.from} → ${trip.to} | maxShippers: ${trip.maxShippers} | status: ${trip.status} | hasAvailableSlots: ${trip.hasAvailableSlots}');
    debugPrint('📍 Coordinates: FROM($fromLatLng) TO($toLatLng)');
    debugPrint('📦 Total trips now in storage: ${allTripsJson.length}');
    
    _tripStreamController.add(null); // Thông báo có thay đổi
    return trip;
  }

  // ========== SHIPPER: XEM DANH SÁCH CHUYẾN TRỐNG ==========
  static Future<List<EmptyTrip>> getAvailableEmptyTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    final trips = <EmptyTrip>[];
    
    debugPrint('📦 Total trips in storage: ${tripsJson.length}');
    
    for (var tripString in tripsJson) {
      try {
        final trip = EmptyTrip.fromJson(tripString);
        debugPrint('🚚 Trip: ${trip.from} → ${trip.to} | Status: ${trip.status} | Slots: ${trip.joinedShippers.length}/${trip.maxShippers} | hasAvailableSlots: ${trip.hasAvailableSlots}');
        
        if (trip.status == 'open' && trip.hasAvailableSlots) {
          trips.add(trip);
          debugPrint('✅ Added to available trips');
        } else {
          debugPrint('❌ Filtered out: status=${trip.status}, hasAvailableSlots=${trip.hasAvailableSlots}');
        }
      } catch (err) {
        debugPrint('Error parsing trip in getAvailableEmptyTrips: $err');
      }
    }
    
    debugPrint('📋 Returning ${trips.length} available trips');
    return trips;
  }

  // ========== SHIPPER: GỬI YÊU CẦU THAM GIA (PENDING) ==========
  static Future<bool> sendJoinRequest({
    required String tripId,
    required String shipperId,
    required String shipperName,
    required String shipperPhone,
    required String cargoType,
    required String cargoWeight,
    required String price,
    required String fromDetail,
    required String toDetail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) {
      debugPrint('❌ sendJoinRequest: Trip not found: $tripId');
      return false;
    }

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    
    debugPrint('📝 sendJoinRequest: tripId=$tripId, shipper=$shipperName');
    debugPrint('   Current joinedShippers: ${trip.joinedShippers.map((s) => s.shipperName).toList()}');

    // Kiểm tra đã gửi request cho TRIP NÀY chưa
    if (trip.joinedShippers.any((s) => s.shipperId == shipperId)) {
      debugPrint('❌ Shipper đã có trong trip này rồi!');
      return false;
    }

    final newRequest = ShipperInTrip(
      shipperId: shipperId,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
      cargoType: cargoType,
      cargoWeight: cargoWeight,
      price: price,
      fromDetail: fromDetail,
      toDetail: toDetail,
      status: 'pending', // Yêu cầu chờ duyệt
    );

    final updatedShippers = [...trip.joinedShippers, newRequest];

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
    );

    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    
    debugPrint('✅ Created pending join request from $shipperName for trip $tripId');
    
    _tripStreamController.add(null);
    return true;
  }

  // ========== SHIPPER: THAM GIA CHUYẾN GHÉP HÀNG (OLD - giữ lại để tương thích) ==========
  static Future<bool> joinEmptyTrip({
    required String tripId,
    required String shipperId,
    required String shipperName,
    required String shipperPhone,
    required String cargoType,
    required String cargoWeight,
    required String price,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) return false;

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);

    if (!trip.hasAvailableSlots || trip.joinedShippers.any((s) => s.shipperId == shipperId)) {
      return false;
    }

    final newShipper = ShipperInTrip(
      shipperId: shipperId,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
      cargoType: cargoType,
      cargoWeight: cargoWeight,
      price: price,
    );

    final updatedShippers = [...trip.joinedShippers, newShipper];
    final newStatus = updatedShippers.length >= trip.maxShippers ? 'full' : trip.status;

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
      status: newStatus,
    );

    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    
    // Tạo order "waiting" cho shipper ngay khi join
    final shipperOrders = prefs.getStringList('shipper_waiting_orders') ?? [];
    final order = {
      'id': '${tripId}_$shipperId',
      'tripId': tripId,
      'shipperId': shipperId,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'driverName': trip.driverName,
      'driverPhone': trip.driverPhone,
      'from': trip.from,
      'to': trip.to,
      'fromDetail': trip.fromAddress,
      'toDetail': trip.toAddress,
      'goods': cargoType,
      'weight': cargoWeight,
      'price': price,
      'receiveDate': trip.pickupTime.toIso8601String(),
      'deliverDate': trip.deliveryTime.toIso8601String(),
      'status': 'waiting', // Đang chờ chuyến đầy
      'createdAt': DateTime.now().toIso8601String(),
      // 📍 IMPORTANT: Include coordinates from trip
      'fromLatLng': trip.fromLatLng != null ? {'lat': trip.fromLatLng!.latitude, 'lng': trip.fromLatLng!.longitude} : null,
      'toLatLng': trip.toLatLng != null ? {'lat': trip.toLatLng!.latitude, 'lng': trip.toLatLng!.longitude} : null,
    };
    shipperOrders.add(jsonEncode(order));
    await prefs.setStringList('shipper_waiting_orders', shipperOrders);
    
    debugPrint('✅ Created waiting order for $shipperName');
    
    _tripStreamController.add(null);
    return true;
  }

  // ========== SHIPPER: HỦY THAM GIA ==========
  static Future<bool> cancelJoinEmptyTrip(String tripId, String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) return false;

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    final updatedShippers = trip.joinedShippers.where((s) => s.shipperId != shipperId).toList();

    // Nếu không có thay đổi, không cần làm gì cả
    if (updatedShippers.length == trip.joinedShippers.length) return false;

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
      status: 'open', // Chuyến sẽ lại mở
    );

    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    _tripStreamController.add(null);
    return true;
  }

  // ========== DRIVER: DUYỆT YÊU CẦU THAM GIA ==========
  static Future<bool> approveJoinRequest(String tripId, String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) return false;

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    
    // Tìm request pending
    final requestIndex = trip.joinedShippers.indexWhere((s) => s.shipperId == shipperId && s.status == 'pending');
    if (requestIndex == -1) return false;

    // Cập nhật status thành 'approved'
    final updatedShippers = List<ShipperInTrip>.from(trip.joinedShippers);
    final request = updatedShippers[requestIndex];
    updatedShippers[requestIndex] = ShipperInTrip(
      shipperId: request.shipperId,
      shipperName: request.shipperName,
      shipperPhone: request.shipperPhone,
      cargoType: request.cargoType,
      cargoWeight: request.cargoWeight,
      price: request.price,
      fromDetail: request.fromDetail,
      toDetail: request.toDetail,
      status: 'approved', // Đã duyệt
    );

    // Kiểm tra xem đã đầy chưa (chỉ đếm approved)
    final approvedCount = updatedShippers.where((s) => s.status == 'approved').length;
    final newStatus = approvedCount >= trip.maxShippers ? 'full' : trip.status;

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
      status: newStatus,
    );

    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    
    // Tạo order waiting cho shipper
    final shipperOrders = prefs.getStringList('shipper_waiting_orders') ?? [];
    
    // 📍 Extract provinces from shipper's fromDetail and toDetail
    // E.g., "Pleiku, Gia Lai" → "Gia Lai", "Nha Trang, Khánh Hòa" → "Khánh Hòa"
    String extractProvince(String detail) {
      final parts = detail.split(',');
      return parts.isNotEmpty ? parts.last.trim() : '';
    }
    
    final shipperFromProvince = request.fromDetail.isNotEmpty ? extractProvince(request.fromDetail) : trip.from;
    final shipperToProvince = request.toDetail.isNotEmpty ? extractProvince(request.toDetail) : trip.to;
    
    final order = {
      'id': '${tripId}_$shipperId',
      'tripId': tripId,
      'shipperId': shipperId,
      'shipperName': request.shipperName,
      'shipperPhone': request.shipperPhone,
      'driverName': trip.driverName,
      'driverPhone': trip.driverPhone,
      'from': shipperFromProvince,  // From shipper's fromDetail
      'to': shipperToProvince,      // From shipper's toDetail
      'fromDetail': request.fromDetail,
      'toDetail': request.toDetail,
      'goods': request.cargoType,
      'weight': request.cargoWeight,
      'price': request.price,
      'receiveDate': trip.pickupTime.toIso8601String(),
      'deliverDate': trip.deliveryTime.toIso8601String(),
      'status': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
      // 📍 Include coordinates from trip (will show trip route until we enhance with shipper input)
      'fromLatLng': trip.fromLatLng != null ? {'lat': trip.fromLatLng!.latitude, 'lng': trip.fromLatLng!.longitude} : null,
      'toLatLng': trip.toLatLng != null ? {'lat': trip.toLatLng!.latitude, 'lng': trip.toLatLng!.longitude} : null,
    };
    shipperOrders.add(jsonEncode(order));
    await prefs.setStringList('shipper_waiting_orders', shipperOrders);
    
    debugPrint('✅ Approved join request from ${request.shipperName}');
    _tripStreamController.add(null);
    return true;
  }

  // ========== DRIVER: TỪ CHỐI YÊU CẦU THAM GIA ==========
  static Future<bool> rejectJoinRequest(String tripId, String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) return false;

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    
    // Xóa request
    final updatedShippers = trip.joinedShippers.where((s) => s.shipperId != shipperId).toList();

    if (updatedShippers.length == trip.joinedShippers.length) return false;

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
    );

    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    
    debugPrint('❌ Rejected join request');
    _tripStreamController.add(null);
    return true;
  }

  // ========== DRIVER: CÁC CHỨC NĂNG KHÁC ==========
  static Future<List<EmptyTrip>> getMyEmptyTrips(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    return allTripsJson
        .map((e) {
          try {
            return EmptyTrip.fromJson(e);
          } catch (err) {
            return null;
          }
        })
        .where((t) => t != null && t.driverId == driverId && (t.status == 'open' || t.status == 'full'))
        .cast<EmptyTrip>()
        .toList();
  }

  // Lấy các chuyến đang giao hoặc đã hoàn thành (lịch sử)
  static Future<List<EmptyTrip>> getMyDeliveringTrips(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    return allTripsJson
        .map((e) {
          try {
            return EmptyTrip.fromJson(e);
          } catch (err) {
            return null;
          }
        })
        .where((t) => t != null && t.driverId == driverId && (t.status == 'delivering' || t.status == 'completed'))
        .cast<EmptyTrip>()
        .toList();
  }

  static Future<void> updateTripStatus(String tripId, String newStatus) async {
     // Logic tương tự, tìm, cập nhật và thông báo stream
  }

  // ========== BẮT ĐẦU GIAO HÀNG (CHUYẾN ĐÃ ĐẦY) ==========
  static Future<void> startDelivering(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);

    if (tripIndex == -1) {
      debugPrint('❌ Trip not found: $tripId');
      return;
    }

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    
    // Cập nhật status chuyến sang 'delivering'
    final updatedTrip = trip.copyWith(status: 'delivering');
    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);

    debugPrint('✅ Updated trip $tripId to delivering');
    debugPrint('📦 Creating orders for ${trip.joinedShippers.length} shippers');

    // Tạo orders "waiting" cho từng shipper đã join
    final shipperOrders = prefs.getStringList('shipper_waiting_orders') ?? [];
    
    for (var shipper in trip.joinedShippers) {
      final order = {
        'id': '${trip.id}_${shipper.shipperId}',
        'tripId': trip.id,
        'shipperId': shipper.shipperId,
        'shipperName': shipper.shipperName,
        'shipperPhone': shipper.shipperPhone,
        'driverName': trip.driverName,
        'driverPhone': trip.driverPhone,
        'from': trip.from,
        'to': trip.to,
        'fromDetail': trip.fromAddress,
        'toDetail': trip.toAddress,
        'goods': shipper.cargoType,
        'weight': shipper.cargoWeight,
        'price': shipper.price,
        'receiveDate': trip.pickupTime.toIso8601String(),
        'deliverDate': trip.deliveryTime.toIso8601String(),
        'status': 'delivering', // Chuyển từ waiting sang delivering ngay
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      shipperOrders.add(jsonEncode(order));
      debugPrint('  ✓ Created order for ${shipper.shipperName}');
    }

    await prefs.setStringList('shipper_waiting_orders', shipperOrders);
    _tripStreamController.add(null);
    
    debugPrint('🎉 All orders created successfully');
  }

  static Future<void> cancelEmptyTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    // Xóa chuyến khỏi danh sách
    final updatedTrips = allTripsJson.where((tripJson) {
      try {
        final trip = EmptyTrip.fromJson(tripJson);
        return trip.id != tripId; // Giữ lại các chuyến không phải là tripId
      } catch (e) {
        return true; // Giữ lại nếu parse lỗi
      }
    }).toList();
    
    await prefs.setStringList(_emptyTripsKey, updatedTrips);
    _tripStreamController.add(null); // Thông báo có thay đổi
  }

  static Future<EmptyTrip?> getEmptyTripDetails(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
      
      for (var tripJson in tripsJson) {
        final trip = EmptyTrip.fromJson(jsonDecode(tripJson));
        if (trip.id == tripId) {
          return trip;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting empty trip details: $e');
      return null;
    }
  }

  // Complete consolidated trip - mark as completed
  static Future<void> completeTrip(String tripId) async {
    debugPrint('✅ Completing consolidated trip: $tripId');
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    final tripIndex = allTripsJson.indexWhere((e) => EmptyTrip.fromJson(e).id == tripId);
    
    if (tripIndex == -1) {
      debugPrint('❌ Trip not found: $tripId');
      return;
    }

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
    final updatedTrip = trip.copyWith(status: 'completed');
    
    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);
    
    debugPrint('  ✅ Trip $tripId marked as completed in empty_trips');
    
    // QUAN TRỌNG: Cập nhật tất cả shipper orders trong shipper_waiting_orders
    final waitingOrdersJson = prefs.getStringList('shipper_waiting_orders') ?? [];
    debugPrint('  📋 Checking ${waitingOrdersJson.length} shipper orders for tripId: $tripId');
    
    int updatedCount = 0;
    final updatedOrders = waitingOrdersJson.map((orderJson) {
      try {
        final order = jsonDecode(orderJson) as Map<String, dynamic>;
        if (order['tripId'] == tripId) {
          debugPrint('    ✓ Found shipper order: ${order['id']}, updating status to completed');
          order['status'] = 'completed';
          updatedCount++;
        }
        return jsonEncode(order);
      } catch (e) {
        debugPrint('    ⚠️ Error parsing order: $e');
        return orderJson;
      }
    }).toList();
    
    await prefs.setStringList('shipper_waiting_orders', updatedOrders);
    debugPrint('  ✅ Updated $updatedCount shipper orders to completed');
    
    _tripStreamController.add(null);
  }

  // Get completed consolidated orders count for a specific driver
  static Future<int> getCompletedConsolidatedOrdersCountForDriver(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    int count = 0;
    for (var tripJson in allTripsJson) {
      try {
        final trip = EmptyTrip.fromJson(tripJson);
        if (trip.driverId == driverId && trip.status == 'completed') {
          count++;
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing trip: $e');
      }
    }
    return count;
  }

  // ========== CLEAR & DEBUG ==========
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emptyTripsKey);
    _tripStreamController.add(null);
  }

  static Future<void> debugPrintStorage() async {
    // ...
  }
}
