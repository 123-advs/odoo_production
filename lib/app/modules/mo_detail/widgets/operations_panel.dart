import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/production_model.dart';
import '../mo_detail_controller.dart';

class OperationsPanel extends GetView<MoDetailController> {
  const OperationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mo = controller.mo.value;
      final productions = controller.productions;
      // Touch the obs so Obx reacts when workorders refresh.
      final _ = controller.workorders.length;
      final hasRunningWo =
          controller.filteredWorkorders.any((w) => w.isProgress);
      final canActual = mo != null && mo.isInProgress && hasRunningWo;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canActual)
            FilledButton.icon(
              onPressed: controller.isMutating.value
                  ? null
                  : controller.openActualWizard,
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('Nhập sản lượng mới'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                backgroundColor: AppColors.primary,
              ),
            )
          else if (mo != null && mo.isDraft)
            const _Hint(
              icon: Icons.info_outline,
              text:
                  'MO chưa bắt đầu. Hãy bấm "Bắt đầu MO" ở tab Vật tư trước.',
            )
          else if (mo != null && mo.isInProgress && !hasRunningWo)
            const _Hint(
              icon: Icons.pause_circle_outline,
              text:
                  'Công đoạn của bạn đang dừng. Hãy bấm "Bắt đầu" ở tab '
                  'Công đoạn trước khi nhập sản lượng.',
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: productions.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: productions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) =>
                        _ProductionCard(production: productions[i]),
                  ),
          ),
        ],
      );
    });
  }
}

class _ProductionCard extends StatelessWidget {
  const _ProductionCard({required this.production});

  final ProductionModel production;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoDetailController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lot ${production.lotName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(production: production),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _Stat(
                  label: 'Sản lượng',
                  value: _fmt(production.actualQty),
                ),
                if (production.pqcDone || production.oqcDone) ...[
                  _Stat(
                    label: 'OK',
                    value: _fmt(production.okQty),
                    color: AppColors.success,
                  ),
                  _Stat(
                    label: 'NG',
                    value: _fmt(production.ngQty),
                    color: AppColors.error,
                  ),
                ],
                if (production.workcenterName != null)
                  _Meta(
                    icon: Icons.precision_manufacturing_outlined,
                    text: production.workcenterName!,
                  ),
              ],
            ),
            if (production.needsQc) ...[
              const SizedBox(height: AppSpacing.md),
              Obx(() => FilledButton.icon(
                    onPressed: c.isMutating.value
                        ? null
                        : () => c.openQc(production),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text('Kiểm tra ${production.qcKind}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      backgroundColor: production.isLastLevel
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  )),
            ] else if (production.pqcDone || production.oqcDone) ...[
              const SizedBox(height: AppSpacing.md),
              Obx(() => OutlinedButton.icon(
                    onPressed: c.isMutating.value
                        ? null
                        : () => c.openQcHistory(production),
                    icon: const Icon(Icons.history),
                    label: Text('Xem lịch sử ${production.qcKind}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.production});

  final ProductionModel production;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _style();
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

  (Color, String) _style() {
    if (production.oqcDone) return (AppColors.success, 'OQC ✓');
    if (production.pqcDone) return (AppColors.success, 'PQC ✓');
    if (production.isLastLevel) return (AppColors.warning, 'Chờ OQC');
    return (AppColors.warning, 'Chờ PQC');
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có lần nhập sản lượng nào.\n'
              'Bấm "Nhập sản lượng mới" để bắt đầu.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
