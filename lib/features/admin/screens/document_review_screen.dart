// lib/features/admin/screens/document_review_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/models/verification_document.dart';

class DocumentReviewScreen extends StatefulWidget {
  final String documentId;

  const DocumentReviewScreen({super.key, required this.documentId});

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  final _verificationService = VerificationService();
  VerificationDocument? _document;
  String? _userName;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    
    final documents = await _verificationService.getAllDocuments();
    final doc = documents.firstWhere(
      (d) => d.id == widget.documentId,
      orElse: () => throw Exception('Document not found'),
    );

    // Load user name from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name_${doc.userId}') ?? 'N/A';

    setState(() {
      _document = doc;
      _userName = userName;
      _isLoading = false;
    });
  }

  Future<void> _approveDocument() async {
    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('user_phone') ?? 'admin';

    final success = await _verificationService.approveDocument(
      widget.documentId,
      adminId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã phê duyệt tài liệu'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi phê duyệt tài liệu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectDocument() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('user_phone') ?? 'admin';

    final success = await _verificationService.rejectDocument(
      widget.documentId,
      adminId,
      reason,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối tài liệu'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi từ chối tài liệu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xem tài liệu', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xem tài liệu', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Không tìm thấy tài liệu')),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(_document!.imageBase64);
    } catch (e) {
      print('Error decoding image: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem tài liệu', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Document info
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _document!.getDocumentTypeName(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Người dùng', value: _userName ?? 'N/A'),
                _InfoRow(label: 'Số điện thoại', value: _document!.userId),
                _InfoRow(
                  label: 'Loại', 
                  value: _document!.userType == 'driver' ? 'Tài xế' : 'Chủ hàng',
                ),
                _InfoRow(label: 'Số tài liệu', value: _document!.documentNumber),
                _InfoRow(
                  label: 'Ngày nộp',
                  value: dateFormat.format(_document!.submittedAt),
                ),
              ],
            ),
          ),

          // Document image
          Expanded(
            child: Container(
              color: Colors.black,
              child: imageBytes != null
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Không thể hiển thị ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),

          // Action buttons
          if (_document!.status == VerificationStatus.pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _rejectDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _approveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Phê duyệt'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Nhập lý do từ chối tài liệu...',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
