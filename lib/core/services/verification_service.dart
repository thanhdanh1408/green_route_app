// lib/core/services/verification_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_document.dart';
import 'notification_service.dart';

class VerificationService {
  static const String _documentsKey = 'verification_documents';
  static const String _userStatusPrefix = 'user_verification_status_';

  // Submit a new document for verification
  Future<bool> submitDocument({
    required String userId,
    required String userType,
    required String documentType,
    required String documentNumber,
    required String imageBase64,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documents = await getAllDocuments();

      // Generate unique ID
      final id = '${userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}';

      // Check if document already exists and is pending/approved
      final existingIndex = documents.indexWhere(
        (doc) => doc.userId == userId && 
                 doc.documentType == documentType && 
                 (doc.status == VerificationStatus.pending || 
                  doc.status == VerificationStatus.approved),
      );

      final newDocument = VerificationDocument(
        id: id,
        userId: userId,
        userType: userType,
        documentType: documentType,
        documentNumber: documentNumber,
        imageBase64: imageBase64,
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        // Replace existing document
        documents[existingIndex] = newDocument;
      } else {
        // Add new document
        documents.add(newDocument);
      }

      // Save to SharedPreferences
      final jsonList = documents.map((doc) => doc.toJson()).toList();
      await prefs.setString(_documentsKey, jsonEncode(jsonList));
      
      print('📄 Document submitted - userId: $userId, documentType: $documentType');
      print('📄 Total documents in storage: ${documents.length}');

      // Update user verification status
      await _updateUserVerificationStatus(userId, userType);

      return true;
    } catch (e) {
      print('❌ Error submitting document: $e');
      return false;
    }
  }

  // Get all documents
  Future<List<VerificationDocument>> getAllDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_documentsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('📄 No documents found in storage');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final result = jsonList
          .map((json) => VerificationDocument.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('📄 Loaded ${result.length} documents from storage');
      return result;
    } catch (e) {
      print('❌ Error getting all documents: $e');
      return [];
    }
  }

  // Get pending documents (for admin)
  Future<List<VerificationDocument>> getPendingDocuments() async {
    final documents = await getAllDocuments();
    final pending = documents
        .where((doc) => doc.status == VerificationStatus.pending)
        .toList();
    print('📋 Pending documents count: ${pending.length}');
    print('📋 Total documents: ${documents.length}');
    for (var doc in documents) {
      print('   - ${doc.userId} (${doc.documentType}): ${doc.status}');
    }
    pending.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    return pending;
  }

  // Get approved documents (for admin)
  Future<List<VerificationDocument>> getApprovedDocuments() async {
    final documents = await getAllDocuments();
    return documents
        .where((doc) => doc.status == VerificationStatus.approved)
        .toList()
      ..sort((a, b) => (b.reviewedAt ?? b.submittedAt).compareTo(a.reviewedAt ?? a.submittedAt));
  }

  // Get rejected documents (for admin)
  Future<List<VerificationDocument>> getRejectedDocuments() async {
    final documents = await getAllDocuments();
    return documents
        .where((doc) => doc.status == VerificationStatus.rejected)
        .toList()
      ..sort((a, b) => (b.reviewedAt ?? b.submittedAt).compareTo(a.reviewedAt ?? a.submittedAt));
  }

  // Get documents for a specific user
  Future<List<VerificationDocument>> getUserDocuments(String userId) async {
    final documents = await getAllDocuments();
    return documents
        .where((doc) => doc.userId == userId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  // Get a specific document by type for a user
  Future<VerificationDocument?> getUserDocumentByType(String userId, String documentType) async {
    final documents = await getUserDocuments(userId);
    final filtered = documents.where((doc) => doc.documentType == documentType).toList();
    
    if (filtered.isEmpty) return null;
    
    // Return the most recent one
    filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return filtered.first;
  }

  // Approve a document (admin action)
  Future<bool> approveDocument(String documentId, String adminId) async {
    final result = await _updateDocumentStatus(
      documentId,
      VerificationStatus.approved,
      adminId,
      null,
    );
    
    // Send notification to user if approved
    if (result) {
      final documents = await getAllDocuments();
      final doc = documents.firstWhere((d) => d.id == documentId);
      await NotificationService.showVerificationApprovedNotification(
        userId: doc.userId,
        documentType: doc.documentType,
      );
    }
    
    return result;
  }

  // Reject a document (admin action)
  Future<bool> rejectDocument(String documentId, String adminId, String reason) async {
    final result = await _updateDocumentStatus(
      documentId,
      VerificationStatus.rejected,
      adminId,
      reason,
    );
    
    // Send notification to user if rejected
    if (result) {
      final documents = await getAllDocuments();
      final doc = documents.firstWhere((d) => d.id == documentId);
      await NotificationService.showVerificationRejectedNotification(
        userId: doc.userId,
        documentType: doc.documentType,
        reason: reason,
      );
    }
    
    return result;
  }

  // Update document status
  Future<bool> _updateDocumentStatus(
    String documentId,
    String status,
    String adminId,
    String? rejectionReason,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documents = await getAllDocuments();

      final index = documents.indexWhere((doc) => doc.id == documentId);
      if (index == -1) {
        return false;
      }

      final updatedDoc = documents[index].copyWith(
        status: status,
        reviewedAt: DateTime.now(),
        reviewedBy: adminId,
        rejectionReason: rejectionReason,
      );

      documents[index] = updatedDoc;

      // Save to SharedPreferences
      final jsonList = documents.map((doc) => doc.toJson()).toList();
      await prefs.setString(_documentsKey, jsonEncode(jsonList));

      // Update user verification status
      await _updateUserVerificationStatus(
        updatedDoc.userId,
        updatedDoc.userType,
      );

      return true;
    } catch (e) {
      print('Error updating document status: $e');
      return false;
    }
  }

  // Check if user is fully verified
  Future<bool> isUserVerified(String userId, String userType) async {
    print('🔐 isUserVerified START: userId=$userId, userType=$userType');
    
    // Admin luôn được xác minh (không cần duyệt tài liệu)
    if (userType == 'admin') {
      print('🔐 isUserVerified RESULT: Admin → true');
      return true;
    }

    // User chưa chọn vai trò → chưa xác minh
    if (userType.isEmpty || userType == 'unknown') {
      print('🔐 isUserVerified RESULT: No role (unknown) → false');
      return false;
    }

    final requiredDocs = DocumentTypes.getRequiredDocuments(userType);
    
    // Nếu không có tài liệu yêu cầu → chưa xác minh
    if (requiredDocs.isEmpty) {
      print('🔐 isUserVerified RESULT: No required docs for $userType → false');
      return false;
    }

    final userDocs = await getUserDocuments(userId);
    print('🔐 isUserVerified: userType=$userType, required=${requiredDocs.length}, userDocs=${userDocs.length}');

    for (final requiredType in requiredDocs) {
      final doc = userDocs.firstWhere(
        (d) => d.documentType == requiredType && d.status == VerificationStatus.approved,
        orElse: () => VerificationDocument(
          id: '',
          userId: '',
          userType: '',
          documentType: '',
          documentNumber: '',
          imageBase64: '',
          status: '',
          submittedAt: DateTime.now(),
        ),
      );

      if (doc.id.isEmpty) {
        print('🔐 isUserVerified RESULT: Missing required doc $requiredType → false');
        return false;
      }
    }

    print('🔐 isUserVerified RESULT: All docs approved → true');
    return true;
  }

  // Get user verification status
  Future<Map<String, dynamic>> getUserVerificationStatus(String userId, String userType) async {
    final isVerified = await isUserVerified(userId, userType);
    final userDocs = await getUserDocuments(userId);
    final requiredDocs = DocumentTypes.getRequiredDocuments(userType);

    int totalRequired = requiredDocs.length;
    int approvedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;

    for (final requiredType in requiredDocs) {
      final doc = userDocs.firstWhere(
        (d) => d.documentType == requiredType,
        orElse: () => VerificationDocument(
          id: '',
          userId: '',
          userType: '',
          documentType: '',
          documentNumber: '',
          imageBase64: '',
          status: '',
          submittedAt: DateTime.now(),
        ),
      );

      if (doc.id.isNotEmpty) {
        if (doc.status == VerificationStatus.approved) {
          approvedCount++;
        } else if (doc.status == VerificationStatus.pending) {
          pendingCount++;
        } else if (doc.status == VerificationStatus.rejected) {
          rejectedCount++;
        }
      }
    }

    return {
      'isVerified': isVerified,
      'totalRequired': totalRequired,
      'approvedCount': approvedCount,
      'pendingCount': pendingCount,
      'rejectedCount': rejectedCount,
      'needsAttention': rejectedCount > 0 || (approvedCount + pendingCount) < totalRequired,
    };
  }

  // Update user verification status in SharedPreferences
  Future<void> _updateUserVerificationStatus(String userId, String userType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = await getUserVerificationStatus(userId, userType);
      await prefs.setString(
        '$_userStatusPrefix$userId',
        jsonEncode(status),
      );
    } catch (e) {
      print('Error updating user verification status: $e');
    }
  }

  // Get pending documents count (for admin badge)
  Future<int> getPendingDocumentsCount() async {
    final pending = await getPendingDocuments();
    return pending.length;
  }

  // Delete a document (if needed)
  Future<bool> deleteDocument(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documents = await getAllDocuments();

      final index = documents.indexWhere((doc) => doc.id == documentId);
      if (index == -1) {
        return false;
      }

      final deletedDoc = documents[index];
      documents.removeAt(index);

      // Save to SharedPreferences
      final jsonList = documents.map((doc) => doc.toJson()).toList();
      await prefs.setString(_documentsKey, jsonEncode(jsonList));

      // Update user verification status
      await _updateUserVerificationStatus(
        deletedDoc.userId,
        deletedDoc.userType,
      );

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
}
