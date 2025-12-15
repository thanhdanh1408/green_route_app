// lib/features/admin/screens/cancel_requests_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class CancelRequestsScreen extends StatefulWidget {
  const CancelRequestsScreen({super.key});

  @override
  State<CancelRequestsScreen> createState() => _CancelRequestsScreenState();
}

class _CancelRequestsScreenState extends State<CancelRequestsScreen> {
  List<Map<String, dynamic>> _cancelRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCancelRequests();
  }

  Future<void> _loadCancelRequests() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getStringList('cancel_requests') ?? [];

    final requests = requestsJson
        .map((json) {
          try {
            return jsonDecode(json) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('Error parsing cancel request: $e');
            return null;
          }
        })
        .where((r) => r != null && r['status'] == 'pending')
        .cast<Map<String, dynamic>>()
        .toList();

    // Sort by requestedAt (newest first)
    requests.sort((a, b) {
      final dateA = DateTime.tryParse(a['requestedAt'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['requestedAt'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    setState(() {
      _cancelRequests = requests;
      _isLoading = false;
    });
  }

  Future<void> _approveCancelRequest(Map<String, dynamic> request) async {
    final orderId = request['orderId'];
    final orderType = request['orderType'] ?? 'regular';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt hủy'),
        content:
            Text('Bạn có chắc chắn muốn duyệt yêu cầu hủy đơn "$orderId"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final outerContext = context; // Capture context before Navigator.pop
              Navigator.pop(outerContext);

              // Show loading
              showDialog(
                context: outerContext,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final prefs = await SharedPreferences.getInstance();

                // Update cancel request status
                final cancelRequests =
                    prefs.getStringList('cancel_requests') ?? [];
                final updatedRequests = cancelRequests.map((json) {
                  final req = jsonDecode(json) as Map<String, dynamic>;
                  if (req['id'] == request['id']) {
                    req['status'] = 'approved';
                    req['approvedAt'] = DateTime.now().toIso8601String();
                  }
                  return jsonEncode(req);
                }).toList();
                await prefs.setStringList('cancel_requests', updatedRequests);

                // Cancel the actual order based on type
                if (orderType == 'consolidated') {
                  // Cancel consolidated trip
                  final trips = prefs.getStringList('empty_trips') ?? [];
                  final updatedTrips = trips.map((json) {
                    final trip = jsonDecode(json) as Map<String, dynamic>;
                    if (trip['id'] == orderId) {
                      trip['status'] = 'failed'; // Status = failed (Đã Hủy)
                      trip['cancelledAt'] = DateTime.now().toIso8601String();
                      trip['cancelledBy'] = 'admin';
                    }
                    return jsonEncode(trip);
                  }).toList();
                  await prefs.setStringList('empty_trips', updatedTrips);

                  // Also update shipper_waiting_orders to mark as failed
                  final shipperOrders =
                      prefs.getStringList('shipper_waiting_orders') ?? [];
                  final updatedOrders = shipperOrders.map((json) {
                    final order = jsonDecode(json) as Map<String, dynamic>;
                    if (order['tripId'] == orderId) {
                      order['status'] = 'failed'; // Status = failed
                    }
                    return jsonEncode(order);
                  }).toList();
                  await prefs.setStringList(
                      'shipper_waiting_orders', updatedOrders);
                } else {
                  // Cancel regular order in driver_bids
                  final driverBids = prefs.getStringList('driver_bids') ?? [];
                  final updatedBids = driverBids.map((json) {
                    final bid = jsonDecode(json) as Map<String, dynamic>;
                    if (bid['orderId'] == orderId) {
                      bid['status'] = 'failed'; // Status = failed (Đã Hủy)
                      bid['cancelledAt'] = DateTime.now().toIso8601String();
                      bid['cancelledBy'] = 'admin';
                    }
                    return jsonEncode(bid);
                  }).toList();
                  await prefs.setStringList('driver_bids', updatedBids);

                  // Also update in shipper_received_bids
                  final shipperBids =
                      prefs.getStringList('shipper_received_bids') ?? [];
                  final updatedShipperBids = shipperBids.map((json) {
                    final bid = jsonDecode(json) as Map<String, dynamic>;
                    if (bid['orderId'] == orderId) {
                      bid['status'] = 'failed'; // Status = failed (Đã Hủy)
                      bid['cancelledAt'] = DateTime.now().toIso8601String();
                      bid['cancelledBy'] = 'admin';
                    }
                    return jsonEncode(bid);
                  }).toList();
                  await prefs.setStringList(
                      'shipper_received_bids', updatedShipperBids);
                }

                if (!mounted) return;
                Navigator.pop(outerContext); // Close loading

                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã duyệt hủy đơn hàng thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );

                _loadCancelRequests();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(outerContext); // Close loading

                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectCancelRequest(Map<String, dynamic> request) async {
    final orderId = request['orderId'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content:
            Text('Bạn có chắc chắn muốn từ chối yêu cầu hủy đơn "$orderId"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final prefs = await SharedPreferences.getInstance();
                final orderType = request['orderType'] ?? 'regular';

                // Update cancel request status
                final cancelRequests =
                    prefs.getStringList('cancel_requests') ?? [];
                final updatedRequests = cancelRequests.map((json) {
                  final req = jsonDecode(json) as Map<String, dynamic>;
                  if (req['id'] == request['id']) {
                    req['status'] = 'rejected';
                    req['rejectedAt'] = DateTime.now().toIso8601String();
                  }
                  return jsonEncode(req);
                }).toList();
                await prefs.setStringList('cancel_requests', updatedRequests);

                // Restore order status back to previous state
                if (orderType == 'consolidated') {
                  final trips = prefs.getStringList('empty_trips') ?? [];
                  final updatedTrips = trips.map((json) {
                    final trip = jsonDecode(json) as Map<String, dynamic>;
                    if (trip['id'] == orderId) {
                      trip['status'] = 'delivering'; // Restore to delivering
                      trip.remove('cancelReason');
                      trip.remove('cancelRequestedAt');
                      trip.remove('cancelRequestedBy');
                    }
                    return jsonEncode(trip);
                  }).toList();
                  await prefs.setStringList('empty_trips', updatedTrips);
                } else {
                  final driverBids = prefs.getStringList('driver_bids') ?? [];
                  final updatedBids = driverBids.map((json) {
                    final bid = jsonDecode(json) as Map<String, dynamic>;
                    if (bid['orderId'] == orderId) {
                      bid['status'] = 'accepted'; // Restore to accepted
                      bid.remove('cancelReason');
                      bid.remove('cancelRequestedAt');
                      bid.remove('cancelRequestedBy');
                    }
                    return jsonEncode(bid);
                  }).toList();
                  await prefs.setStringList('driver_bids', updatedBids);

                  final shipperBids =
                      prefs.getStringList('shipper_received_bids') ?? [];
                  final updatedShipperBids = shipperBids.map((json) {
                    final bid = jsonDecode(json) as Map<String, dynamic>;
                    if (bid['orderId'] == orderId) {
                      bid['status'] = 'accepted';
                      bid.remove('cancelReason');
                      bid.remove('cancelRequestedAt');
                      bid.remove('cancelRequestedBy');
                    }
                    return jsonEncode(bid);
                  }).toList();
                  await prefs.setStringList(
                      'shipper_received_bids', updatedShipperBids);
                }

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã từ chối yêu cầu hủy đơn!'),
                    backgroundColor: Colors.orange,
                  ),
                );

                _loadCancelRequests();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu hủy đơn',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cancelRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không có yêu cầu hủy đơn nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCancelRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cancelRequests.length,
                    itemBuilder: (context, index) {
                      final request = _cancelRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final orderId = request['orderId'] ?? 'N/A';
    final shortOrderId =
        orderId.length > 20 ? '${orderId.substring(0, 20)}...' : orderId;
    final orderType = request['orderType'] ?? 'regular';
    final requestedBy = request['requestedBy'] ?? 'unknown';
    final reason = request['reason'] ?? 'Không có lý do';
    final requestedAt = request['requestedAt'];

    DateTime? requestDate;
    if (requestedAt != null) {
      try {
        requestDate = DateTime.parse(requestedAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    final dateStr = requestDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(requestDate)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: orderType == 'consolidated'
                        ? Colors.orange
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    orderType == 'consolidated' ? 'Đơn ghép' : 'Đơn thường',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    requestedBy == 'driver' ? 'Tài xế' : 'Chủ hàng',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mã đơn: $shortOrderId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Lý do hủy:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                reason,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectCancelRequest(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveCancelRequest(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
