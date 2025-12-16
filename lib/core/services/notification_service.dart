import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize notification service - call this in main.dart
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  // Callback when user taps notification
  static void _onNotificationTap(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // You can add navigation logic here based on payload
  }

  // ==================== VERIFICATION NOTIFICATIONS ====================

  /// Show notification when document is approved
  static Future<void> showVerificationApprovedNotification({
    required String userId,
    required String documentType,
  }) async {
    await _showNotification(
      id: _generateId(userId, 'verification_approved'),
      title: 'Xác minh thành công',
      body: 'Tài liệu $documentType của bạn đã được phê duyệt ✅',
      payload: 'verification:approved:$userId:$documentType',
    );
  }

  /// Show notification when document is rejected
  static Future<void> showVerificationRejectedNotification({
    required String userId,
    required String documentType,
    required String reason,
  }) async {
    await _showNotification(
      id: _generateId(userId, 'verification_rejected'),
      title: 'Xác minh bị từ chối',
      body: 'Tài liệu $documentType: $reason ❌',
      payload: 'verification:rejected:$userId:$documentType',
    );
  }

  // ==================== TRANSACTION NOTIFICATIONS ====================

  /// Show notification for deposit request status change
  static Future<void> showDepositStatusNotification({
    required String userId,
    required String amount,
    required String status, // 'approved', 'rejected', 'pending'
  }) async {
    String title, body;

    switch (status) {
      case 'approved':
        title = 'Nạp tiền thành công';
        body = 'Khoản nạp $amount đã được phê duyệt ✅';
        break;
      case 'rejected':
        title = 'Nạp tiền bị từ chối';
        body = 'Khoản nạp $amount đã bị từ chối ❌';
        break;
      default:
        title = 'Nạp tiền đang xử lý';
        body = 'Khoản nạp $amount đang chờ phê duyệt ⏳';
    }

    await _showNotification(
      id: _generateId(userId, 'deposit_$status'),
      title: title,
      body: body,
      payload: 'transaction:deposit:$userId:$status:$amount',
    );
  }

  /// Show notification for withdrawal request status change
  static Future<void> showWithdrawalStatusNotification({
    required String userId,
    required String amount,
    required String status, // 'approved', 'rejected', 'pending'
  }) async {
    String title, body;

    switch (status) {
      case 'approved':
        title = 'Rút tiền thành công';
        body = 'Khoản rút $amount đã hoàn tất ✅';
        break;
      case 'rejected':
        title = 'Rút tiền bị từ chối';
        body = 'Khoản rút $amount đã bị từ chối ❌';
        break;
      default:
        title = 'Rút tiền đang xử lý';
        body = 'Khoản rút $amount đang chờ phê duyệt ⏳';
    }

    await _showNotification(
      id: _generateId(userId, 'withdrawal_$status'),
      title: title,
      body: body,
      payload: 'transaction:withdrawal:$userId:$status:$amount',
    );
  }

  // ==================== ORDER NOTIFICATIONS ====================

  /// Show notification when new order is available (for drivers)
  static Future<void> showNewOrderAvailableNotification({
    required String driverId,
    required String orderId,
    required String pickupLocation,
    required String destination,
    required String distance,
  }) async {
    await _showNotification(
      id: _generateId(driverId, 'new_order_$orderId'),
      title: 'Đơn hàng mới khả dụng 🎯',
      body: '$pickupLocation → $destination ($distance km)',
      payload: 'order:new:$orderId:$driverId',
    );
  }

  /// Show notification when order status changes
  static Future<void> showOrderStatusNotification({
    required String userId,
    required String orderId,
    required String newStatus,
    required String details,
  }) async {
    String title, emoji;

    switch (newStatus) {
      case 'assigned':
        title = 'Đơn hàng được giao cho bạn';
        emoji = '✋';
        break;
      case 'in_transit':
        title = 'Đơn hàng đang trên đường';
        emoji = '🚗';
        break;
      case 'arrived':
        title = 'Đã tới nơi đón khách';
        emoji = '📍';
        break;
      case 'completed':
        title = 'Đơn hàng hoàn tất';
        emoji = '✅';
        break;
      case 'cancelled':
        title = 'Đơn hàng bị hủy';
        emoji = '❌';
        break;
      default:
        title = 'Cập nhật trạng thái đơn hàng';
        emoji = '📦';
    }

    await _showNotification(
      id: _generateId(userId, 'order_status_$orderId'),
      title: '$emoji $title',
      body: details,
      payload: 'order:status:$orderId:$newStatus',
    );
  }

  // ==================== EMPTY TRIP NOTIFICATIONS ====================

  /// Show notification when shipper wants to join empty trip
  static Future<void> showTripJoinRequestNotification({
    required String driverId,
    required String shipperId,
    required String shipperName,
    required String tripId,
    required String tripDetails,
  }) async {
    await _showNotification(
      id: _generateId(driverId, 'trip_request_$tripId'),
      title: 'Shipper muốn chuyến ghép 🤝',
      body: '$shipperName: $tripDetails',
      payload: 'trip:request:$tripId:$driverId:$shipperId',
    );
  }

  /// Show notification when driver approves shipper's empty trip request
  static Future<void> showTripApprovedNotification({
    required String shipperId,
    required String tripId,
    required String driverName,
  }) async {
    await _showNotification(
      id: _generateId(shipperId, 'trip_approved_$tripId'),
      title: 'Chuyến ghép được chấp nhận ✅',
      body: 'Driver $driverName đã chấp nhận yêu cầu của bạn',
      payload: 'trip:approved:$tripId:$shipperId',
    );
  }

  /// Show notification when driver rejects shipper's empty trip request
  static Future<void> showTripRejectedNotification({
    required String shipperId,
    required String tripId,
  }) async {
    await _showNotification(
      id: _generateId(shipperId, 'trip_rejected_$tripId'),
      title: 'Chuyến ghép bị từ chối ❌',
      body: 'Driver không chấp nhận yêu cầu chuyến ghép của bạn',
      payload: 'trip:rejected:$tripId:$shipperId',
    );
  }

  // ==================== BOOKING/BID NOTIFICATIONS ====================

  /// Show notification when driver bids on shipper's booking
  static Future<void> showBidReceivedNotification({
    required String shipperId,
    required String bookingId,
    required String driverName,
    required String bidAmount,
  }) async {
    await _showNotification(
      id: _generateId(shipperId, 'bid_received_$bookingId'),
      title: 'Có lời chào mới 💬',
      body: '$driverName lời chào: $bidAmount',
      payload: 'booking:bid:$bookingId:$shipperId:$driverName',
    );
  }

  /// Show notification when shipper accepts driver's bid
  static Future<void> showBidAcceptedNotification({
    required String driverId,
    required String bookingId,
    required String shipperName,
  }) async {
    await _showNotification(
      id: _generateId(driverId, 'bid_accepted_$bookingId'),
      title: 'Lời chào được chấp nhận ✅',
      body: '$shipperName đã chấp nhận lời chào của bạn',
      payload: 'booking:accepted:$bookingId:$driverId',
    );
  }

  /// Show notification when shipper rejects driver's bid
  static Future<void> showBidRejectedNotification({
    required String driverId,
    required String bookingId,
    required String shipperName,
  }) async {
    await _showNotification(
      id: _generateId(driverId, 'bid_rejected_$bookingId'),
      title: 'Lời chào bị từ chối ❌',
      body: '$shipperName đã từ chối lời chào của bạn',
      payload: 'booking:rejected:$bookingId:$driverId',
    );
  }

  // ==================== WALLET NOTIFICATIONS ====================

  /// Show notification when balance changes (payment received, refund, etc.)
  static Future<void> showWalletUpdateNotification({
    required String userId,
    required String transactionType, // 'payment', 'refund', 'reward'
    required String amount,
    required String description,
  }) async {
    String title, emoji;

    switch (transactionType) {
      case 'payment':
        title = 'Thanh toán thành công';
        emoji = '💳';
        break;
      case 'refund':
        title = 'Hoàn tiền';
        emoji = '💰';
        break;
      case 'reward':
        title = 'Nhận thưởng';
        emoji = '🎁';
        break;
      case 'earnings':
        title = 'Nhận thu nhập';
        emoji = '💵';
        break;
      default:
        title = 'Cập nhật ví';
        emoji = '💼';
    }

    await _showNotification(
      id: _generateId(userId, 'wallet_${transactionType}_${DateTime.now().millisecondsSinceEpoch}'),
      title: '$emoji $title',
      body: '$description: $amount',
      payload: 'wallet:update:$userId:$transactionType:$amount',
    );
  }

  // ==================== INTERNAL HELPERS ====================

  /// Core method to show notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'green_route_channel',
        'Green Route Notifications',
        channelDescription:
            'Thông báo từ ứng dụng Green Route - Vận chuyển xanh',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: const Color.fromARGB(255, 34, 139, 34), // Forest green
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('📲 Notification shown: [$id] $title - $body');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Generate unique ID from userId and action type
  static int _generateId(String userId, String action) {
    final combined = '$userId-$action';
    return combined.hashCode.abs() % 2147483647; // Ensure positive int32
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
