import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/production_model.dart';
import '../../../widgets/numpad.dart';

class QcResult {
  QcResult({required this.okQty, required this.ngQty});

  final double okQty;
  final double ngQty;
}

/// Modal capturing OK / NG split for one `mrp.production` row.
/// Validation: ok + ng must equal `production.actualQty` (server-side
/// tolerates other splits but UX is cleaner if we enforce it client-side).
class QcModal extends StatefulWidget {
  const QcModal({super.key, required this.production});

  final ProductionModel production;

  @override
  State<QcModal> createState() => _QcModalState();
}

class _QcModalState extends State<QcModal> {
  late String _okText;
  String _ngText = '0';

  @override
  void initState() {
    super.initState();
    // Default OK = full actual_qty so the most common path is just
    // tap "Xác nhận" without typing.
    _okText = _fmt(widget.production.actualQty);
  }

  double get _ok => double.tryParse(_okText) ?? 0;
  double get _ng => double.tryParse(_ngText) ?? 0;
  double get _total => _ok + _ng;
  bool get _matches => (_total - widget.production.actualQty).abs() < 0.0001;

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.production;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    p.isLastLevel ? Icons.verified_outlined : Icons.fact_check_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kiểm tra chất lượng — ${p.qcKind}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Lot: ${p.lotName}  ·  Sản lượng: '
                          '${_fmt(p.actualQty)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Get.back<QcResult?>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 600;
                    final ok = _NumpadCol(
                      label: 'OK',
                      color: AppColors.success,
                      value: _okText,
                      onChanged: (v) => setState(() => _okText = v),
                      autofocus: true,
                    );
                    final ng = _NumpadCol(
                      label: 'NG',
                      color: AppColors.error,
                      value: _ngText,
                      onChanged: (v) => setState(() => _ngText = v),
                      autofocus: false,
                    );
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: ok),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(child: ng),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                ok,
                                const SizedBox(height: AppSpacing.lg),
                                ng,
                              ],
                            ),
                          );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _totalLine(),
              const SizedBox(height: AppSpacing.md),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalLine() {
    final color = _matches ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _matches ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tổng: ${_fmt(_ok)} OK + ${_fmt(_ng)} NG = ${_fmt(_total)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (!_matches)
            Text(
              'Cần ${_fmt(widget.production.actualQty)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Get.back<QcResult?>(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, AppSpacing.buttonHeight),
          ),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _matches
              ? () => Get.back<QcResult?>(
                    result: QcResult(okQty: _ok, ngQty: _ng),
                  )
              : null,
          icon: const Icon(Icons.check_rounded),
          label: Text('Xác nhận ${widget.production.qcKind}'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(180, AppSpacing.buttonHeight),
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _NumpadCol extends StatelessWidget {
  const _NumpadCol({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final Color color;
  final String value;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm - 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Numpad(
              value: value,
              onChanged: onChanged,
              allowDecimal: true,
              autofocus: autofocus,
            ),
          ],
        ),
      ),
    );
  }
}
