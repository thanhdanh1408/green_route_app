import 'package:flutter/material.dart';
import '../../../core/constants/terms_policies.dart';

class TermsAndPoliciesScreen extends StatefulWidget {
  final String? initialTermType;
  final List<String>? availableTerms; // Danh sách các term được phép hiển thị

  const TermsAndPoliciesScreen({
    Key? key,
    this.initialTermType,
    this.availableTerms,
  }) : super(key: key);

  @override
  State<TermsAndPoliciesScreen> createState() => _TermsAndPoliciesScreenState();
}

class _TermsAndPoliciesScreenState extends State<TermsAndPoliciesScreen> {
  late String selectedTerm;

  @override
  void initState() {
    super.initState();
    // Nếu có availableTerms, dùng danh sách đó; nếu không, dùng tất cả
    final termsToShow = widget.availableTerms ?? TermsAndPolicies.allTerms.keys.toList();
    selectedTerm = widget.initialTermType ?? termsToShow.first;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách term được phép hiển thị
    final termsToShow = widget.availableTerms ?? TermsAndPolicies.allTerms.keys.toList();
    final filteredTerms = termsToShow
        .where((key) => TermsAndPolicies.allTerms.containsKey(key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản & Chính sách'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar để chọn loại điều khoản
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: filteredTerms.map((key) {
                  final isSelected = selectedTerm == key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(
                        TermsAndPolicies.termsTitle[key] ?? '',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedTerm = key;
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.green,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Nội dung điều khoản
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                TermsAndPolicies.allTerms[selectedTerm] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Footer button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Tôi đã đọc và đồng ý',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
