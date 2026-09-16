import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeStatus { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status) {
      case BadgeStatus.success:
        backgroundColor = AppColors.success;
        break;
      case BadgeStatus.warning:
        backgroundColor = AppColors.warning;
        textColor = Colors.black87;
        break;
      case BadgeStatus.error:
        backgroundColor = AppColors.error;
        break;
      case BadgeStatus.info:
        backgroundColor = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
