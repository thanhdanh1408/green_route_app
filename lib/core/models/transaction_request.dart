// lib/core/models/transaction_request.dart

class TransactionRequest {
  final String id;
  final String userId;
  final String type; // 'deposit' or 'withdraw'
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? adminNotes;
  
  // For deposit: proof image base64
  final String? proofImageBase64;
  
  // For withdraw: bank account info
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  TransactionRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.status = 'pending',
    required this.createdAt,
    this.approvedAt,
    this.adminNotes,
    this.proofImageBase64,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'adminNotes': adminNotes,
      'proofImageBase64': proofImageBase64,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
  }

  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      adminNotes: json['adminNotes'] as String?,
      proofImageBase64: json['proofImageBase64'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountHolder: json['accountHolder'] as String?,
    );
  }

  TransactionRequest copyWith({
    String? status,
    DateTime? approvedAt,
    String? adminNotes,
  }) {
    return TransactionRequest(
      id: id,
      userId: userId,
      type: type,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      proofImageBase64: proofImageBase64,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
    );
  }
}
