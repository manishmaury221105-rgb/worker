import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.replaceAll('_', ' ');

    switch (status.toUpperCase()) {
      case 'PRESENT':
      case 'ACTIVE':
      case 'APPROVED':
      case 'PAID':
      case 'COMPLETED':
      case 'REIMBURSED':
        bg = AppColors.success.withOpacity(0.14);
        fg = AppColors.success;
        break;

      case 'LATE':
      case 'IN_PROGRESS':
      case 'HALF_DAY':
      case 'PENDING':
      case 'URGENT':
      case 'DRAFT':
        bg = AppColors.warning.withOpacity(0.14);
        fg = const Color(0xFFD97706); // Darker Amber
        break;

      case 'ABSENT':
      case 'INACTIVE':
      case 'REJECTED':
      case 'CANCELLED':
      case 'HIGH':
        bg = AppColors.error.withOpacity(0.14);
        fg = AppColors.error;
        break;

      case 'ON_LEAVE':
      case 'MEDIUM':
      case 'LOW':
      default:
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
