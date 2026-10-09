import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CompanyLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;
  final bool hasShadow;
  final VoidCallback? onTap;

  const CompanyLogo({
    super.key,
    this.size = 48,
    this.showBorder = true,
    this.borderWidth = 2.0,
    this.borderColor,
    this.hasShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? const Color(0xFFFBBF24);

    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: (borderColor ?? AppColors.accent).withOpacity(0.3),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF0C2461),
              child: Icon(
                Icons.business_rounded,
                color: AppColors.accentLight,
                size: size * 0.5,
              ),
            );
          },
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logo,
      );
    }

    return logo;
  }
}
