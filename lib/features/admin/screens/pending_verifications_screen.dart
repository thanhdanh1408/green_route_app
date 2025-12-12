// lib/features/admin/screens/pending_verifications_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/verification_service.dart';
import '../../../core/models/verification_document.dart';
import 'document_review_screen.dart';

class PendingVerificationsScreen extends StatefulWidget {
  const PendingVerificationsScreen({super.key});

  @override
  State<PendingVerificationsScreen> createState() => _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState extends State<PendingVerificationsScreen> with SingleTickerProviderStateMixin {
  final _verificationService = VerificationService();
  late TabController _tabController;
  List<VerificationDocument> _allDocuments = [];
  List<VerificationDocument> _driverDocuments = [];
  List<VerificationDocument> _shipperDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final documents = await _verificationService.getPendingDocuments();
    setState(() {
      _allDocuments = documents;
      _driverDocuments = documents.where((doc) => doc.userType == 'driver').toList();
      _shipperDocuments = documents.where((doc) => doc.userType == 'shipper').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu chờ duyệt', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Tất cả (${_allDocuments.length})'),
            Tab(text: 'Tài xế (${_driverDocuments.length})'),
            Tab(text: 'Chủ hàng (${_shipperDocuments.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentList(_allDocuments),
                  _buildDocumentList(_driverDocuments),
                  _buildDocumentList(_shipperDocuments),
                ],
              ),
      ),
    );
  }

  Widget _buildDocumentList(List<VerificationDocument> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không có tài liệu chờ duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _DocumentCard(
          document: doc,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentReviewScreen(documentId: doc.id),
              ),
            );
            _loadDocuments();
          },
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final VerificationDocument document;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: document.userType == 'driver' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  document.userType == 'driver' 
                      ? Icons.local_shipping 
                      : Icons.business,
                  color: document.userType == 'driver' 
                      ? Colors.blue 
                      : Colors.purple,
                ),
              ),
              const SizedBox(width: 16),

              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.getDocumentTypeName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${document.userId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(document.submittedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
