import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable button with configurable parameters. Put at: lib/core/widgets/custom_button.dart

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double radius;
  final Widget? leading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
    this.radius = 12,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final txt = textColor ?? Colors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: AppTheme.roundedButtonStyle(
          backgroundColor: bg,
          radius: radius,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: txt,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
