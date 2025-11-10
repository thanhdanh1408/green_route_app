import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/auth_input_field.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen1 extends StatefulWidget {
  const RegisterScreen1({super.key});

  @override
  State<RegisterScreen1> createState() => _RegisterScreen1State();
}

class _RegisterScreen1State extends State<RegisterScreen1> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Số điện thoại'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Chúng tôi sẽ gửi mã xác nhận qua số điện thoại của bạn',
                style: AppTextStyle.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AuthInputField(
                hint: 'Nhập số điện thoại',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Image.asset('assets/icons/vietnam_flag.webp', width: 24),
                    const SizedBox(width: 8),
                    const Text('+84'),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                label: 'Tiếp tục',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Thành công → chuyển sang màn OTP
                    Navigator.pushNamed(context, '/register2');
                  }
                },
              ),
              const Spacer(),
              const Text(
                'Khi tiếp tục, bạn chấp nhận Điều khoản và Chính sách của chúng tôi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}