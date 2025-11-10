import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/custom_button.dart';
import '/features/auth/widgets/auth_input_field.dart';
import '/core/utils/validators.dart';

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

  final List<String> banks = [
    'Techcombank', 'Vietcombank', 'ACB', 'MBBank', 'Sacombank',
  ];

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
            children: [
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: const InputDecoration(labelText: 'Tên ngân hàng'),
                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => selectedBank = v),
                validator: (v) => v == null ? 'Vui lòng chọn ngân hàng' : null,
              ),
              const SizedBox(height: AppPadding.normal),
              AuthInputField(hint: 'Số tài khoản', controller: _accountNumberController, validator: Validators.validateAccountNumber),
              const SizedBox(height: AppPadding.normal),
              AuthInputField(hint: 'Tên chủ tài khoản', controller: _accountNameController, validator: Validators.validateNotEmpty),
              const SizedBox(height: AppPadding.normal),
              AuthInputField(hint: 'Chi nhánh (Tùy chọn)', controller: _branchController),
              const SizedBox(height: 30),
              CustomButton(
                label: 'Lưu',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushNamed(context, '/bank_complete', arguments: selectedBank);
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