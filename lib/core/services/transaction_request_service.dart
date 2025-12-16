// lib/core/services/transaction_request_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/transaction_request.dart';

class TransactionRequestService {
  static const String _storageKey = 'transaction_requests';
  static const String _adminStorageKey = 'admin_info';

  // Lưu admin bank info (để hiển thị cho user khi nạp tiền)
  static Future<void> setAdminBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final adminInfo = {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
    await prefs.setString(_adminStorageKey, jsonEncode(adminInfo));
  }

  // Lấy admin bank info để hiển thị
  static Future<Map<String, String>> getAdminBankInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_adminStorageKey);
    if (data == null) {
      return {
        'bankName': 'Ngân hàng Vietcombank',
        'accountNumber': '0991234567',
        'accountHolder': 'GREEN ROUTE JSC',
      };
    }
    return Map<String, String>.from(jsonDecode(data) as Map<String, dynamic>);
  }

  // Tạo request nạp tiền với proof image
  static Future<bool> createDepositRequest({
    required String userId,
    required double amount,
    required String proofImageBase64,
  }) async {
    try {
      final request = TransactionRequest(
        id: 'txreq_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: 'deposit',
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
        proofImageBase64: proofImageBase64,
      );

      return await _saveRequest(request);
    } catch (e) {
      debugPrint('❌ Error creating deposit request: $e');
      return false;
    }
  }

  // Tạo request rút tiền
  static Future<bool> createWithdrawRequest({
    required String userId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    try {
      final request = TransactionRequest(
        id: 'txreq_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: 'withdraw',
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
      );

      return await _saveRequest(request);
    } catch (e) {
      debugPrint('❌ Error creating withdraw request: $e');
      return false;
    }
  }

  // Lưu request
  static Future<bool> _saveRequest(TransactionRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requests = prefs.getStringList(_storageKey) ?? [];
      requests.insert(0, jsonEncode(request.toJson()));
      
      // Giữ lịch sử 500 request gần nhất
      if (requests.length > 500) {
        requests.removeRange(500, requests.length);
      }
      
      await prefs.setStringList(_storageKey, requests);
      debugPrint('✅ Transaction request saved: ${request.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving transaction request: $e');
      return false;
    }
  }

  // Lấy requests của user
  static Future<List<TransactionRequest>> getUserRequests(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_storageKey) ?? [];
      
      return requestsJson
          .map((json) => TransactionRequest.fromJson(
              jsonDecode(json) as Map<String, dynamic>))
          .where((req) => req.userId == userId)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user requests: $e');
      return [];
    }
  }

  // Lấy tất cả pending requests (cho admin)
  static Future<List<TransactionRequest>> getPendingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_storageKey) ?? [];
      
      return requestsJson
          .map((json) => TransactionRequest.fromJson(
              jsonDecode(json) as Map<String, dynamic>))
          .where((req) => req.status == 'pending')
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting pending requests: $e');
      return [];
    }
  }

  // Admin duyệt request
  static Future<bool> approveRequest(
    String requestId, {
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_storageKey) ?? [];
      
      final updatedRequests = <String>[];
      bool found = false;
      
      for (final json in requestsJson) {
        final req = TransactionRequest.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        
        if (req.id == requestId) {
          final approved = req.copyWith(
            status: 'approved',
            approvedAt: DateTime.now(),
            adminNotes: notes,
          );
          updatedRequests.add(jsonEncode(approved.toJson()));
          found = true;
        } else {
          updatedRequests.add(json);
        }
      }
      
      if (!found) return false;
      
      await prefs.setStringList(_storageKey, updatedRequests);
      debugPrint('✅ Transaction request approved: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Error approving transaction request: $e');
      return false;
    }
  }

  // Admin từ chối request
  static Future<bool> rejectRequest(
    String requestId,
    String reason,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_storageKey) ?? [];
      
      final updatedRequests = <String>[];
      bool found = false;
      
      for (final json in requestsJson) {
        final req = TransactionRequest.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        
        if (req.id == requestId) {
          final rejected = req.copyWith(
            status: 'rejected',
            adminNotes: reason,
          );
          updatedRequests.add(jsonEncode(rejected.toJson()));
          found = true;
        } else {
          updatedRequests.add(json);
        }
      }
      
      if (!found) return false;
      
      await prefs.setStringList(_storageKey, updatedRequests);
      debugPrint('✅ Transaction request rejected: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting transaction request: $e');
      return false;
    }
  }

  // Lấy chi tiết request
  static Future<TransactionRequest?> getRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_storageKey) ?? [];
      
      for (final json in requestsJson) {
        final req = TransactionRequest.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        if (req.id == requestId) {
          return req;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting transaction request: $e');
      return null;
    }
  }
}
