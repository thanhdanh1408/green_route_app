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

    // Lưu vào danh sách chuyến chung
    final allTrips = prefs.getStringList(_emptyTripsKey) ?? [];
    allTrips.add(trip.toJson());
    await prefs.setStringList(_emptyTripsKey, allTrips);

    // Lưu vào danh sách chuyến của driver
    final myTrips = prefs.getStringList(_myTripsKey) ?? [];
    myTrips.add(trip.toJson());
    await prefs.setStringList(_myTripsKey, myTrips);

    debugPrint('✅ Created empty trip: ${trip.id}');
    return trip;
  }

  // ========== SHIPPER: XEM DANH SÁCH CHUYẾN TRỐNG ==========
  static Future<List<EmptyTrip>> getAvailableEmptyTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final trips = tripsJson
        .map((e) => EmptyTrip.fromJson(e))
        .where((t) => t.status == 'open' && t.hasAvailableSlots)
        .toList();

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
    final prefs = await SharedPreferences.getInstance();
    final allTripsJson = prefs.getStringList(_emptyTripsKey) ?? [];

    final tripIndex = allTripsJson.indexWhere((e) {
      final trip = EmptyTrip.fromJson(e);
      return trip.id == tripId;
    });

    if (tripIndex == -1) {
      debugPrint('❌ Trip not found: $tripId');
      return false;
    }

    final trip = EmptyTrip.fromJson(allTripsJson[tripIndex]);

    // Kiểm tra còn chỗ hay không
    if (!trip.hasAvailableSlots) {
      debugPrint('❌ Trip is full: $tripId');
      return false;
    }

    // Kiểm tra shipper chưa join chưa
    final alreadyJoined = trip.joinedShippers.any((s) => s.shipperId == shipperId);
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
    final myTripsJson = prefs.getStringList(_myTripsKey) ?? [];

    final trips = myTripsJson
        .map((e) => EmptyTrip.fromJson(e))
        .where((t) => t.driverId == driverId)
        .toList();

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
}
