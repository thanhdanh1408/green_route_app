// lib/core/services/rating_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class DriverRating {
  final String ratingId;
  final String driverId;
  final String shipperId;
  final String orderId;
  final int rating; // 1-5
  final String review;
  final DateTime timestamp;

  DriverRating({
    required this.ratingId,
    required this.driverId,
    required this.shipperId,
    required this.orderId,
    required this.rating,
    required this.review,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'ratingId': ratingId,
      'driverId': driverId,
      'shipperId': shipperId,
      'orderId': orderId,
      'rating': rating,
      'review': review,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      ratingId: json['ratingId'] ?? '',
      driverId: json['driverId'] ?? '',
      shipperId: json['shipperId'] ?? '',
      orderId: json['orderId'] ?? '',
      rating: json['rating'] ?? 5,
      review: json['review'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RatingService {
  static const String _ratingsKey = 'driver_ratings';

  /// Add a new rating for a driver
  static Future<void> addRating({
    required String driverId,
    required String shipperId,
    required String orderId,
    required int rating,
    required String review,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if already rated
    final hasRated = await hasRatedOrder(orderId, shipperId);
    if (hasRated) {
      debugPrint('⚠️ Order $orderId already rated by shipper $shipperId');
      return;
    }

    final newRating = DriverRating(
      ratingId: const Uuid().v4(),
      driverId: driverId,
      shipperId: shipperId,
      orderId: orderId,
      rating: rating,
      review: review,
      timestamp: DateTime.now(),
    );

    final ratings = prefs.getStringList(_ratingsKey) ?? [];
    ratings.add(jsonEncode(newRating.toJson()));
    await prefs.setStringList(_ratingsKey, ratings);

    debugPrint('✅ Added rating: $rating stars for driver $driverId on order $orderId');
  }

  /// Get average rating for a driver
  static Future<double> getDriverRating(String driverId) async {
    final ratings = await getDriverRatings(driverId);
    
    if (ratings.isEmpty) {
      return 0.0;
    }

    final sum = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
    return sum / ratings.length;
  }

  /// Get all ratings for a specific driver
  static Future<List<DriverRating>> getDriverRatings(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getStringList(_ratingsKey) ?? [];

    final driverRatings = <DriverRating>[];
    for (final jsonStr in ratingsJson) {
      try {
        final rating = DriverRating.fromJson(jsonDecode(jsonStr));
        if (rating.driverId == driverId) {
          driverRatings.add(rating);
        }
      } catch (e) {
        debugPrint('Error parsing rating: $e');
      }
    }

    // Sort by newest first
    driverRatings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return driverRatings;
  }

  /// Check if a shipper has already rated an order
  static Future<bool> hasRatedOrder(String orderId, String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getStringList(_ratingsKey) ?? [];

    for (final jsonStr in ratingsJson) {
      try {
        final rating = DriverRating.fromJson(jsonDecode(jsonStr));
        if (rating.orderId == orderId && rating.shipperId == shipperId) {
          return true;
        }
      } catch (e) {
        debugPrint('Error parsing rating: $e');
      }
    }

    return false;
  }

  /// Get total number of ratings for a driver
  static Future<int> getDriverRatingCount(String driverId) async {
    final ratings = await getDriverRatings(driverId);
    return ratings.length;
  }

  /// Get rating for a specific order (if exists)
  static Future<DriverRating?> getOrderRating(String orderId, String shipperId) async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getStringList(_ratingsKey) ?? [];

    for (final jsonStr in ratingsJson) {
      try {
        final rating = DriverRating.fromJson(jsonDecode(jsonStr));
        if (rating.orderId == orderId && rating.shipperId == shipperId) {
          return rating;
        }
      } catch (e) {
        debugPrint('Error parsing rating: $e');
      }
    }

    return null;
  }

  /// Clear all ratings (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratingsKey);
    debugPrint('🧹 Cleared all ratings');
  }
}
