import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StateBadge extends StatelessWidget {
  const StateBadge(this.state, {super.key});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static (Color, String) _styleFor(String state) {
    switch (state) {
      case 'draft':
        return (AppColors.accent, 'Mới');
      case 'in_progress':
        return (AppColors.warning, 'Đang chạy');
      case 'done':
        return (AppColors.success, 'Hoàn tất');
      case 'cancel':
        return (AppColors.error, 'Đã hủy');
      default:
        return (AppColors.textMuted, state);
    }
  }
}
