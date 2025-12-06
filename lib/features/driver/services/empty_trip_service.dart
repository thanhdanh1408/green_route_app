import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/empty_trip_model.dart';

class EmptyTripService {
  static const String _emptyTripsKey = 'empty_trips';
  static const String _myTripsKey = 'driver_empty_trips'; // Chuyến của driver hiện tại

  // ========== DRIVER: TẠO CHUYẾN TRỐNG ==========
  static Future<EmptyTrip> createEmptyTrip({
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String from,
    required String to,
    required String containerType,
    required String capacity,
    required String proposedPrice,
    required DateTime pickupTime,
    required DateTime deliveryTime,
    required int maxShippers,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final trip = EmptyTrip(
      id: const Uuid().v4(),
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      from: from,
      to: to,
      containerType: containerType,
      capacity: capacity,
      proposedPrice: proposedPrice,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      maxShippers: maxShippers,
      status: 'open',
    );

    // Lưu vào danh sách chuyến chung (lưu dưới dạng JSON string)
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    allTripsJson.add(trip.toJson());
    await prefs.setStringList(_emptyTripsKey, allTripsJson);

    debugPrint('✅ Created empty trip: ${trip.id}');
    debugPrint('📌 Total trips in storage: ${allTripsJson.length}');
    return trip;
  }

  // ========== SHIPPER: XEM DANH SÁCH CHUYẾN TRỐNG ==========
  static Future<List<EmptyTrip>> getAvailableEmptyTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    debugPrint('🔍 getAvailableEmptyTrips: Found ${tripsJson.length} total trips in storage');

    final trips = <EmptyTrip>[];
    
    for (var i = 0; i < tripsJson.length; i++) {
      try {
        final trip = EmptyTrip.fromJson(tripsJson[i]);
        final isOpen = trip.status == 'open';
        final hasSlots = trip.hasAvailableSlots;
        debugPrint('   Trip $i: id=${trip.id}, from=${trip.from}→${trip.to}, status=${trip.status}, hasSlots=$hasSlots, joined=${trip.joinedShippers.length}/${trip.maxShippers}');
        
        if (isOpen && hasSlots) {
          trips.add(trip);
        }
      } catch (err) {
        debugPrint('❌ Error parsing trip at index $i: $err');
      }
    }

    debugPrint('✅ Available trips found: ${trips.length}');
    return trips;
  }

  // ========== SHIPPER: THAM GIA CHUYẾN GHÉP HÀNG ==========
  static Future<bool> joinEmptyTrip({
    required String tripId,
    required String shipperId,
    required String shipperName,
    required String shipperPhone,
    required String cargoType,
    required String cargoWeight,
    required String price,
  }) async {
    debugPrint('🔍 joinEmptyTrip called:');
    debugPrint('  tripId: $tripId');
    debugPrint('  shipperId: $shipperId');
    debugPrint('  shipperName: $shipperName');

    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    debugPrint('📊 Total trips in storage: ${allTripsJson.length}');

    final tripIndex = allTripsJson.indexWhere((e) {
      final trip = EmptyTrip.fromJson(e);
      return trip.id == tripId;
    });

    if (tripIndex == -1) {
      debugPrint('❌ Trip not found: $tripId');
      return false;
    }

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);

    debugPrint('📍 Trip found at index $tripIndex');
    debugPrint('   Status: ${trip.status}');
    debugPrint('   Joined: ${trip.joinedShippers.length}/${trip.maxShippers}');
    debugPrint('   Joined shippers: ${trip.joinedShippers.map((s) => '${s.shipperId}(${s.shipperName})').toList()}');
    debugPrint('   Raw JSON joinedShippers: ${trip.joinedShippers.map((s) => s.toMap()).toList()}');

    // Kiểm tra còn chỗ hay không
    if (!trip.hasAvailableSlots) {
      debugPrint('❌ Trip is full: $tripId');
      return false;
    }

    // Kiểm tra shipper chưa join chưa
    final alreadyJoined = trip.joinedShippers.any((s) => s.shipperId == shipperId);
    debugPrint('✓ Already joined check: $alreadyJoined');
    
    if (alreadyJoined) {
      debugPrint('❌ Shipper already joined: $shipperId');
      return false;
    }

    // Thêm shipper vào danh sách
    final newShipper = ShipperInTrip(
      shipperId: shipperId,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
      cargoType: cargoType,
      cargoWeight: cargoWeight,
      price: price,
      status: 'pending',
    );

    final updatedShippers = [...trip.joinedShippers, newShipper];

    debugPrint('✅ Adding new shipper: $shipperId');
    debugPrint('   New joined count: ${updatedShippers.length}');

    // Cập nhật trạng thái trip (nếu đầy thì đổi thành 'full')
    final newStatus = updatedShippers.length >= trip.maxShippers ? 'full' : trip.status;

    final updatedTrip = trip.copyWith(
      joinedShippers: updatedShippers,
      status: newStatus,
    );

    // Lưu lại
    allTripsJson[tripIndex] = updatedTrip.toJson();
    await prefs.setStringList(_emptyTripsKey, allTripsJson);

    debugPrint('✅ Shipper joined trip: $shipperId → $tripId');
    return true;
  }

  // ========== DRIVER: LẤY DANH SÁCH CHUYẾN CỦA TÔI ==========
  static Future<List<EmptyTrip>> getMyEmptyTrips(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final trips = <EmptyTrip>[];
    for (var i = 0; i < allTripsJson.length; i++) {
      try {
        final trip = EmptyTrip.fromJson(allTripsJson[i]);
        if (trip.driverId == driverId) {
          trips.add(trip);
        }
      } catch (err) {
        debugPrint('❌ Error parsing trip at index $i: $err');
      }
    }

    debugPrint('🔍 getMyEmptyTrips: Found ${trips.length} trips for driver $driverId');
    return trips;
  }

  // ========== DRIVER: CẬP NHẬT TRẠNG THÁI CHUYẾN ==========
  static Future<void> updateTripStatus(String tripId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final tripIndex = allTripsJson.indexWhere((e) {
      final trip = EmptyTrip.fromJson(e);
      return trip.id == tripId;
    });

    if (tripIndex != -1) {
      final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);
      final updatedTrip = trip.copyWith(status: newStatus);
      allTripsJson[tripIndex] = updatedTrip.toJson();
      await prefs.setStringList(_emptyTripsKey, allTripsJson);

      debugPrint('✅ Updated trip status: $tripId → $newStatus');
    }
  }

  // ========== DRIVER: RỜI KHỎI/HỦY CHUYẾN ==========
  static Future<void> cancelEmptyTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    allTripsJson.removeWhere((e) {
      final trip = EmptyTrip.fromJson(e);
      return trip.id == tripId;
    });

    await prefs.setStringList(_emptyTripsKey, allTripsJson);

    debugPrint('✅ Cancelled empty trip: $tripId');
  }

  // ========== SHIPPER: LẤY CHI TIẾT CHUYẾN ==========
  static Future<EmptyTrip?> getEmptyTripDetails(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    try {
      return tripsJson
          .map((e) => EmptyTrip.fromJson(e))
          .firstWhere((t) => t.id == tripId);
    } catch (e) {
      return null;
    }
  }

  // ========== CLEAR ALL DATA ==========
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emptyTripsKey);
    await prefs.remove(_myTripsKey);
  }

  // ========== DIAGNOSTIC: CHECK STORAGE ==========
  static Future<void> debugPrintStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];
    
    debugPrint('📊 === STORAGE DIAGNOSTIC ===');
    debugPrint('Total trips stored: ${allTripsJson.length}');
    
    for (int i = 0; i < allTripsJson.length; i++) {
      try {
        final trip = EmptyTrip.fromJson(allTripsJson[i]);
        debugPrint('  Trip $i: id=${trip.id}, from=${trip.from}→${trip.to}, status=${trip.status}, joined=${trip.joinedShippers.length}/${trip.maxShippers}');
      } catch (e) {
        debugPrint('  ❌ Trip $i: PARSE ERROR - $e');
      }
    }
    debugPrint('========================');
  }
}
