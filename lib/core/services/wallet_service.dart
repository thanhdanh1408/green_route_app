// lib/core/services/wallet_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class WalletService {
  // Transaction types
  static const String typeCredit = 'credit';
  static const String typeDebit = 'debit';

  /// Get wallet balance for user
  static Future<double> getBalance(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final balances = prefs.getString('wallet_balances') ?? '{}';
    final balanceMap = jsonDecode(balances) as Map<String, dynamic>;
    return (balanceMap[userId] ?? 0).toDouble();
  }

  /// Set wallet balance for user
  static Future<void> _setBalance(String userId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final balances = prefs.getString('wallet_balances') ?? '{}';
    final balanceMap = jsonDecode(balances) as Map<String, dynamic>;
    balanceMap[userId] = amount;
    await prefs.setString('wallet_balances', jsonEncode(balanceMap));
  }

  /// Add transaction and update balance
  static Future<bool> addTransaction({
    required String userId,
    required String type, // 'credit' or 'debit'
    required double amount,
    required String description,
    String? relatedId, // Trip ID, Order ID, etc.
    String? category, // 'earnings', 'deposit', 'withdrawal', 'refund'
  }) async {
    try {
      final currentBalance = await getBalance(userId);
      
      // Check if user has enough balance for debit
      if (type == typeDebit && currentBalance < amount) {
        debugPrint('❌ Insufficient balance: have $currentBalance, need $amount');
        return false;
      }

      // Calculate new balance
      final newBalance = type == typeCredit 
          ? currentBalance + amount 
          : currentBalance - amount;

      // Create transaction record
      final transaction = {
        'id': 'tx_${DateTime.now().millisecondsSinceEpoch}',
        'type': type,
        'amount': amount,
        'description': description,
        'relatedId': relatedId,
        'category': category ?? 'earnings', // Default to earnings
        'balance': newBalance, // Balance after transaction
        'date': DateTime.now().toIso8601String(),
      };

      // Save transaction
      final prefs = await SharedPreferences.getInstance();
      final transactionsKey = 'transactions_$userId';
      final transactionsJson = prefs.getStringList(transactionsKey) ?? [];
      transactionsJson.insert(0, jsonEncode(transaction)); // Add to front (newest first)
      
      // Keep only last 1000 transactions
      if (transactionsJson.length > 1000) {
        transactionsJson.removeRange(1000, transactionsJson.length);
      }
      
      await prefs.setStringList(transactionsKey, transactionsJson);

      // Update balance
      await _setBalance(userId, newBalance);

      debugPrint('✅ Transaction added: $type ${amount}đ, new balance: ${newBalance}đ');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding transaction: $e');
      return false;
    }
  }

  /// Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactions(String userId, {int limit = 100}) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsKey = 'transactions_$userId';
    final transactionsJson = prefs.getStringList(transactionsKey) ?? [];
    
    return transactionsJson
        .take(limit)
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  /// Top-up wallet (simulated)
  static Future<bool> topUp(String userId, double amount) async {
    return await addTransaction(
      userId: userId,
      type: typeCredit,
      amount: amount,
      description: 'Nạp tiền vào ví',
    );
  }

  /// Withdraw from wallet (simulated)
  static Future<bool> withdraw(String userId, double amount) async {
    return await addTransaction(
      userId: userId,
      type: typeDebit,
      amount: amount,
      description: 'Rút tiền từ ví',
    );
  }

  /// Add earnings from completed trip (Driver)
  static Future<bool> addTripEarnings(String userId, double amount, String tripId) async {
    return await addTransaction(
      userId: userId,
      type: typeCredit,
      amount: amount,
      description: 'Thu nhập từ chuyến hàng',
      relatedId: tripId,
    );
  }

  /// Deduct payment for order (Shipper)
  static Future<bool> deductOrderPayment(String userId, double amount, String orderId) async {
    return await addTransaction(
      userId: userId,
      type: typeDebit,
      amount: amount,
      description: 'Thanh toán đơn hàng',
      relatedId: orderId,
    );
  }

  /// Get earnings summary (today, week, month)
  static Future<Map<String, double>> getEarningsSummary(String userId) async {
    final transactions = await getTransactions(userId, limit: 1000);
    final now = DateTime.now();
    
    // Tính ngày đầu tiên của tuần (Thứ 2)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    
    double today = 0;
    double thisWeek = 0;
    double thisMonth = 0;

    for (var tx in transactions) {
      // Only count 'credit' type
      if (tx['type'] != typeCredit) continue;
      
      // Determine category: use stored category, or detect from description
      String category = tx['category'] ?? 'earnings';
      if (category == 'earnings') {
        // For backward compatibility: detect deposit/withdrawal from description
        final description = (tx['description'] ?? '').toString().toLowerCase();
        if (description.contains('nạp tiền')) {
          category = 'deposit';
        } else if (description.contains('rút tiền')) {
          category = 'withdrawal';
        }
      }
      
      // Skip non-earnings transactions
      if (category != 'earnings') continue;
      
      final txDate = DateTime.parse(tx['date']);
      final amount = (tx['amount'] as num).toDouble();
      final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);

      // Today
      if (txDateOnly == nowDate) {
        today += amount;
      }

      // This week (from Monday to today, and within same month)
      if (!txDateOnly.isBefore(weekStartDate) && !nowDate.isBefore(txDateOnly)) {
        thisWeek += amount;
      }

      // This month
      if (txDate.year == now.year && txDate.month == now.month) {
        thisMonth += amount;
      }
    }

    return {
      'today': today,
      'thisWeek': thisWeek,
      'thisMonth': thisMonth,
    };
  }

  /// Format currency (Vietnamese Dong)
  static String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    // Add thousand separators
    final parts = <String>[];
    var remaining = formatted;
    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }
    return '${parts.join('.')} đ';
  }
}
