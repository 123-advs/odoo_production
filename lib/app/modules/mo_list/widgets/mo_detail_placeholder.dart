import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/mo_model.dart';
import '../../../widgets/state_badge.dart';

class MoDetailPlaceholder extends StatelessWidget {
  const MoDetailPlaceholder({super.key, this.mo, this.onOpen});

  final MoModel? mo;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final m = mo;
    if (m == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 64, color: AppColors.textMuted),
              SizedBox(height: AppSpacing.md),
              Text(
                'Chọn một MO bên trái để xem chi tiết',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                m.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StateBadge(m.state),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            m.productName ?? m.productCode ?? '—',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _Stat(label: 'Mục tiêu', value: _fmt(m.targetQty)),
                  const _Divider(),
                  _Stat(label: 'Thực tế', value: _fmt(m.actualQty)),
                  const _Divider(),
                  _Stat(label: 'Còn lại', value: _fmt(m.remainQty)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (onOpen != null)
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Mở MO'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}
