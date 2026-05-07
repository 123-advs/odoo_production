import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/mo_detail_model.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/state_badge.dart';

/// Compact header — keeps the essentials visible in ~140dp so the tab
/// content (items / workorders / etc.) gets the lion's share of the screen.
/// Layout: title row · product line · stats+progress row · meta row.
class MoHeader extends StatelessWidget {
  const MoHeader({super.key, required this.mo});

  final MoDetailModel mo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: MO name + state badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    mo.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StateBadge(mo.state),
              ],
            ),
            const SizedBox(height: 2),
            // Row 2: product name + code on a single line
            Text(
              _productLine(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Row 3: stats + progress bar — single row using LayoutBuilder
            LayoutBuilder(
              builder: (context, constraints) {
                final tight = constraints.maxWidth < 720;
                if (tight) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statsRow(),
                      const SizedBox(height: AppSpacing.sm),
                      _progressBar(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _statsRow()),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 4, child: _progressBar()),
                  ],
                );
              },
            ),
            // Row 4: meta info — compact, single-line wrap
            if (_hasMeta()) ...[
              const SizedBox(height: AppSpacing.sm),
              _metaRow(),
            ],
          ],
        ),
      ),
    );
  }

  String _productLine() {
    final parts = <String>[];
    if (mo.productCode != null) parts.add(mo.productCode!);
    parts.add(mo.productName);
    return parts.join(' · ');
  }

  /// User's selected workcenter (from picker) — preferred over the MO's
  /// `working_line_id` because multiple workers on different lines can
  /// share the same MO; the header should reflect THIS worker's line.
  /// Falls back to MO's workingLineName when the user hasn't picked one
  /// (cold-start edge case).
  String? get _displayLineName {
    final picked = Get.find<StorageService>().workcenterName;
    if (picked != null && picked.isNotEmpty) return picked;
    return mo.workingLineName;
  }

  bool _hasMeta() =>
      _displayLineName != null ||
      mo.sourceLocationName != null ||
      mo.destLocationName != null;

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Mục tiêu', value: _fmt(mo.targetQty))),
        Expanded(
          child: _Stat(
            label: 'Thực tế',
            value: _fmt(mo.actualQty),
            color: AppColors.warning,
          ),
        ),
        Expanded(
          child: _Stat(
            label: 'Còn lại',
            value: _fmt(mo.remainQty),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _progressBar() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mo.progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                mo.isDone ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 44,
          child: Text(
            '${(mo.progress * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        if (_displayLineName != null)
          _Meta(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Dây chuyền',
            value: _displayLineName!,
          ),
        if (mo.sourceLocationName != null)
          _Meta(
            icon: Icons.warehouse_outlined,
            label: 'Lấy',
            value: mo.sourceLocationName!,
          ),
        if (mo.destLocationName != null)
          _Meta(
            icon: Icons.outbound_outlined,
            label: 'Trả',
            value: mo.destLocationName!,
          ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
