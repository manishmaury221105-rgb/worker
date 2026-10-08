import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ButtonVariant { primary, success, danger, warning, outline, secondary }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final double height;
  final double? width;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.height = 52,
    this.width,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case ButtonVariant.success:
        bg = AppColors.success;
        fg = Colors.white;
        break;
      case ButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case ButtonVariant.warning:
        bg = AppColors.warning;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = const Color(0xFF475569);
        fg = Colors.white;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == ButtonVariant.outline ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
