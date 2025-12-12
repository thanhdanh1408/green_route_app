// lib/core/models/verification_document.dart
class VerificationDocument {
  final String id;
  final String userId; // Phone number
  final String userType; // 'driver' or 'shipper'
  final String documentType; // 'id_card_front', 'id_card_back', 'vehicle_registration', etc.
  final String documentNumber;
  final String imageBase64; // Store image as base64 string
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin phone/ID
  final String? rejectionReason;

  VerificationDocument({
    required this.id,
    required this.userId,
    required this.userType,
    required this.documentType,
    required this.documentNumber,
    required this.imageBase64,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'imageBase64': imageBase64,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  // Create from JSON
  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userType: json['userType'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      imageBase64: json['imageBase64'] as String,
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt'] as String) 
          : null,
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // Create a copy with updated fields
  VerificationDocument copyWith({
    String? id,
    String? userId,
    String? userType,
    String? documentType,
    String? documentNumber,
    String? imageBase64,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      imageBase64: imageBase64 ?? this.imageBase64,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // Helper method to get localized document type name
  String getDocumentTypeName() {
    switch (documentType) {
      case 'id_card_front':
        return 'CCCD/CMND (Mặt trước)';
      case 'id_card_back':
        return 'CCCD/CMND (Mặt sau)';
      case 'vehicle_registration':
        return 'Giấy đăng ký xe';
      case 'driver_license_front':
        return 'Giấy phép lái xe (Mặt trước)';
      case 'driver_license_back':
        return 'Giấy phép lái xe (Mặt sau)';
      case 'business_license':
        return 'Giấy phép kinh doanh';
      default:
        return documentType;
    }
  }

  // Helper method to get status color
  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }
}

// Document type constants
class DocumentTypes {
  static const String idCardFront = 'id_card_front';
  static const String idCardBack = 'id_card_back';
  static const String vehicleRegistration = 'vehicle_registration';
  static const String driverLicenseFront = 'driver_license_front';
  static const String driverLicenseBack = 'driver_license_back';
  static const String businessLicense = 'business_license';

  // Get required documents for user type
  static List<String> getRequiredDocuments(String userType) {
    if (userType == 'driver') {
      return [
        idCardFront,
        idCardBack,
        vehicleRegistration,
        driverLicenseFront,
        driverLicenseBack,
      ];
    } else if (userType == 'shipper') {
      return [
        idCardFront,
        idCardBack,
      ];
    }
    return [];
  }

  // Get optional documents for user type
  static List<String> getOptionalDocuments(String userType) {
    if (userType == 'shipper') {
      return [businessLicense];
    }
    return [];
  }
}

// Verification status constants
class VerificationStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}
