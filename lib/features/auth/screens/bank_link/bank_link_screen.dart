import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';
import '/features/auth/widgets/auth_input_field.dart';

class BankLinkScreen extends StatefulWidget {
  const BankLinkScreen({super.key});

  @override
  State<BankLinkScreen> createState() => _BankLinkScreenState();
}

class _BankLinkScreenState extends State<BankLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedBank;
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _branchController = TextEditingController();
  bool _isLoading = false;

  final List<String> banks = [
    'Techcombank', 'Vietcombank', 'ACB', 'MBBank', 'Sacombank',
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Liên kết ngân hàng nhận tiền'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Liên kết tài khoản ngân hàng',
                style: AppTextStyle.headline2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chúng tôi sẽ chuyển tiền vào tài khoản này',
                style: AppTextStyle.body,
              ),
              const SizedBox(height: 24),

              const Text('Tên ngân hàng *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: InputDecoration(
                  hintText: 'Chọn ngân hàng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => selectedBank = v),
                validator: (v) => v == null ? 'Vui lòng chọn ngân hàng' : null,
              ),
              const SizedBox(height: 16),

              const Text('Số tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Số tài khoản',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
              ),
              const SizedBox(height: 16),

              const Text('Tên chủ tài khoản *', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Tên chủ tài khoản',
                controller: _accountNameController,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên chủ tài khoản' : null,
              ),
              const SizedBox(height: 16),

              const Text('Chi nhánh (Tùy chọn)', style: AppTextStyle.body),
              const SizedBox(height: 8),
              AuthInputField(
                hint: 'Chi nhánh',
                controller: _branchController,
              ),
              const Spacer(),

              CustomButton(
                label: 'Hoàn tất',
                loading: _isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('bank', selectedBank ?? '');
                  await prefs.setString('account', _accountNumberController.text);
                  await prefs.setString('account_name', _accountNameController.text);

                  setState(() => _isLoading = false);

                  if (mounted) {
                    // Sau khi link ngân hàng, chuyển đến register_complete
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/register_complete',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
