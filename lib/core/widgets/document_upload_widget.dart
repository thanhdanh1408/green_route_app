// lib/core/widgets/document_upload_widget.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/verification_document.dart';
import '../services/verification_service.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String userId;
  final String userType;
  final String documentType;
  final String documentLabel;
  final VoidCallback? onDocumentChanged;

  const DocumentUploadWidget({
    super.key,
    required this.userId,
    required this.userType,
    required this.documentType,
    required this.documentLabel,
    this.onDocumentChanged,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  final _verificationService = VerificationService();
  final _imagePicker = ImagePicker();
  VerificationDocument? _document;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didUpdateWidget(DocumentUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload document if userId changed
    if (oldWidget.userId != widget.userId) {
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    final doc = await _verificationService.getUserDocumentByType(
      widget.userId,
      widget.documentType,
    );
    setState(() {
      _document = doc;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // Read image bytes
      final bytes = await pickedFile.readAsBytes();
      
      // Compress image if too large (> 500KB)
      Uint8List imageBytes = bytes;
      if (bytes.length > 500000) {
        final image = img.decodeImage(bytes);
        if (image != null) {
          // Resize to reasonable size
          final resized = img.copyResize(image, width: 1200);
          imageBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        }
      }

      // Convert to base64
      final base64Image = base64Encode(imageBytes);

      // Submit document (no need to ask for document number)
      final success = await _verificationService.submitDocument(
        userId: widget.userId,
        userType: widget.userType,
        documentType: widget.documentType,
        documentNumber: '', // Empty documentNumber
        imageBase64: base64Image,
      );

      if (mounted) {
        setState(() => _isUploading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload tài liệu thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDocument();
          widget.onDocumentChanged?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi upload tài liệu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview() {
    if (_document == null) return;
    
    try {
      final imageBytes = base64Decode(_document!.imageBase64);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.documentLabel),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(imageBytes),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error showing image preview: $e');
    }
  }

  Color _getStatusColor() {
    if (_document == null) return Colors.grey;
    switch (_document!.status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (_document == null) return Icons.upload_file;
    switch (_document!.status) {
      case VerificationStatus.pending:
        return Icons.pending;
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.upload_file;
    }
  }

  String _getStatusText() {
    if (_document == null) return 'Chưa upload';
    return _document!.getStatusText();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _document != null ? _showImagePreview : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.documentLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      icon: Icon(
                        _document == null || _document!.status == VerificationStatus.rejected
                            ? Icons.upload
                            : Icons.refresh,
                        color: _document == null || _document!.status == VerificationStatus.rejected
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      onPressed: _showImageSourceDialog,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              
              // Rejection reason
              if (_document?.status == VerificationStatus.rejected &&
                  _document?.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            'Lý do từ chối:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _document!.rejectionReason!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
