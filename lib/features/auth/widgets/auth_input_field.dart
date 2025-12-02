import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';

class AuthInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefixIcon;

  const AuthInputField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTextStyle.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}