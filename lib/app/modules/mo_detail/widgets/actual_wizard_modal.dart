import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/actual_wizard_model.dart';
import '../../../data/models/bom_info_model.dart';
import '../../../widgets/numpad.dart';

class ActualWizardResult {
  ActualWizardResult({
    required this.actualQty,
    required this.usingQtyByLineId,
    required this.otherLossByLineId,
  });

  final double actualQty;
  final Map<int, double> usingQtyByLineId;
  final Map<int, double> otherLossByLineId;
}

class ActualWizardModal extends StatefulWidget {
  const ActualWizardModal({
    super.key,
    required this.wizard,
    required this.bom,
  });

  final ActualWizardModel wizard;
  final BomInfoModel? bom;

  @override
  State<ActualWizardModal> createState() => _ActualWizardModalState();
}

class _ActualWizardModalState extends State<ActualWizardModal> {
  String _qtyText = '';

  final Map<int, double> _overrides = {};

  final Map<int, double> _losses = {};

  double get _qty => double.tryParse(_qtyText) ?? 0;

  void _onActualQtyChanged(String v) {
    setState(() {
      _qtyText = v;

      if (v.isEmpty) _overrides.clear();
    });
  }

  void _setOverride(int lineId, double qty) {
    setState(() => _overrides[lineId] = qty);
  }

  void _clearOverride(int lineId) {
    setState(() => _overrides.remove(lineId));
  }

  double _lossFor(int lineId) {
    if (_losses.containsKey(lineId)) return _losses[lineId]!;
    final line =
        widget.wizard.lines.where((l) => l.id == lineId).firstOrNull;
    return line?.otherLoss ?? 0;
  }

  bool _isLossOverride(int lineId) => _losses.containsKey(lineId);

  void _setLoss(int lineId, double qty) {
    setState(() => _losses[lineId] = qty);
  }

  void _clearLoss(int lineId) {
    setState(() => _losses.remove(lineId));
  }

  Future<void> _editLoss(ActualWizardLine line) async {
    final qty = await Get.dialog<double>(
      _LineLossModal(line: line, initialQty: _lossFor(line.id)),
      barrierDismissible: false,
    );
    if (qty == null) return;
    if (qty < 0) return;
    _setLoss(line.id, qty);
  }

  Map<int, double> _computeBaseUsing() {
    final result = <int, double>{};
    final actual = _qty;
    final bom = widget.bom;
    for (final line in widget.wizard.lines) {
      result[line.id] = 0;
    }
    if (actual <= 0 || bom == null || bom.productQty <= 0) {
      for (final entry in _overrides.entries) {
        result[entry.key] = entry.value;
      }
      return result;
    }
    final ratio = actual / bom.productQty;

    final byProduct = <int, List<ActualWizardLine>>{};
    for (final line in widget.wizard.lines) {
      byProduct.putIfAbsent(line.productId, () => []).add(line);
    }
    for (final entry in byProduct.entries) {
      final bomLine = bom.lines
          .where((b) => b.productId == entry.key)
          .firstOrNull;
      if (bomLine == null) continue;
      var needed = ratio * bomLine.requiredQty;

      for (final line in entry.value) {
        if (_overrides.containsKey(line.id)) {
          final v = _overrides[line.id]!;
          result[line.id] = v;
          needed -= v;
        }
      }
      final auto = entry.value
          .where((l) => !_overrides.containsKey(l.id))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      for (final line in auto) {
        if (needed <= 0) break;
        final take = math.min(line.remainQty, needed);
        if (take > 0) {
          result[line.id] = double.parse(take.toStringAsFixed(4));
          needed -= take;
        }
      }
    }
    return result;
  }

  Map<int, double> _computeUsing() {
    final base = _computeBaseUsing();
    final result = <int, double>{};
    for (final line in widget.wizard.lines) {
      final b = base[line.id] ?? 0;
      final l = _lossFor(line.id);
      result[line.id] =
          double.parse((b + l).toStringAsFixed(4));
    }
    return result;
  }

  Future<void> _editLine(ActualWizardLine line, double _) async {
    final base = _computeBaseUsing()[line.id] ?? 0;
    final qty = await Get.dialog<double>(
      _LineQtyModal(line: line, initialQty: base),
      barrierDismissible: false,
    );
    if (qty == null) return;
    if (qty < 0) return;
    _setOverride(line.id, qty);
  }

  String? _validateUsing(Map<int, double> using) {
    final bom = widget.bom;
    if (bom == null) return null;
    final actual = _qty;
    if (actual <= 0) return 'Vui lòng nhập số lượng > 0';
    final ratio = actual / (bom.productQty > 0 ? bom.productQty : 1);
    final byProduct = <int, List<ActualWizardLine>>{};
    for (final line in widget.wizard.lines) {
      byProduct.putIfAbsent(line.productId, () => []).add(line);
    }
    for (final bomLine in bom.lines) {
      final lines = byProduct[bomLine.productId] ?? [];
      final totalLoss =
          lines.fold<double>(0, (s, l) => s + _lossFor(l.id));
      final required = ratio * bomLine.requiredQty + totalLoss;
      final available =
          lines.fold<double>(0, (sum, l) => sum + l.remainQty);
      if (available + 0.0001 < required) {
        final productName = lines.firstOrNull?.productName ?? '?';
        return 'Vật tư "$productName" thiếu '
            '(cần ${_fmt(required)}, còn ${_fmt(available)})';
      }
    }
    return null;
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String? _overshootHint() {
    final actual = _qty;
    if (actual > widget.wizard.remainQty + 0.0001) {
      final over = actual - widget.wizard.remainQty;
      return 'Vượt mục tiêu MO ${_fmt(over)} '
          '(còn lại ${_fmt(widget.wizard.remainQty)})';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 4, child: _numpadPane()),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 5, child: _breakdownPane()),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _numpadPane(),
                                const SizedBox(height: AppSpacing.lg),
                                _breakdownPane(),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _bottomActions(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    final w = widget.wizard;
    return Row(
      children: [
        const Icon(Icons.bar_chart_rounded,
            color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập sản lượng thực tế',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (w.productSemiName != null && w.productSemiName!.isNotEmpty)
                Text(
                  w.productSemiName!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          child: Text(
            'Còn lại: ${_fmt(w.remainQty)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Get.back<ActualWizardResult?>(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _numpadPane() {
    return Numpad(
      label: 'Số lượng thực tế',
      value: _qtyText,
      onChanged: _onActualQtyChanged,
    );
  }

  Widget _breakdownPane() {
    final using = _computeUsing();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 18, color: AppColors.textMuted),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Vật tư sẽ tiêu hao',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tự tính theo BOM. Nếu vật tư không đủ, hệ thống sẽ '
              'từ chối khi xác nhận.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: widget.wizard.lines.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Không có vật tư nào để tiêu hao.\n'
                          'Hãy chắc rằng có item ở trạng thái "Đã xác nhận".',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      itemCount: widget.wizard.lines.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final line = widget.wizard.lines[i];
                        final use = using[line.id] ?? 0;
                        final loss = _lossFor(line.id);
                        final overflow = use > line.remainQty + 0.0001;
                        final isUseOverride =
                            _overrides.containsKey(line.id);
                        final isLossOverride = _isLossOverride(line.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.productName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Lot: ${line.lotName} · còn '
                                      '${_fmt(line.remainQty)} ${line.uom}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _LineQtyBadge(
                                label: 'Dùng',
                                value: use,
                                uom: line.uom,
                                isOverride: isUseOverride,
                                color: overflow
                                    ? AppColors.error
                                    : isUseOverride
                                        ? AppColors.warning
                                        : AppColors.primary,
                                onTap: () => _editLine(line, use),
                                onReset: isUseOverride
                                    ? () => _clearOverride(line.id)
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _LineQtyBadge(
                                label: 'Hao',
                                value: loss,
                                uom: line.uom,
                                isOverride: isLossOverride,
                                color: loss > 0
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                onTap: () => _editLoss(line),
                                onReset: isLossOverride
                                    ? () => _clearLoss(line.id)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() {
    final using = _computeUsing();
    final err = _validateUsing(using);
    final overshoot = err == null ? _overshootHint() : null;
    return Row(
      children: [
        if (err != null)
          Expanded(
            child: Text(
              err,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (overshoot != null)
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    overshoot,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Get.back<ActualWizardResult?>(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, AppSpacing.buttonHeight),
          ),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: err != null
              ? null
              : () {
                  final losses = <int, double>{};
                  for (final line in widget.wizard.lines) {
                    losses[line.id] = _lossFor(line.id);
                  }
                  Get.back<ActualWizardResult?>(
                    result: ActualWizardResult(
                      actualQty: _qty,
                      usingQtyByLineId: using,
                      otherLossByLineId: losses,
                    ),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Xác nhận'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(160, AppSpacing.buttonHeight),
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _LineQtyBadge extends StatelessWidget {
  const _LineQtyBadge({
    required this.label,
    required this.value,
    required this.uom,
    required this.isOverride,
    required this.color,
    required this.onTap,
    this.onReset,
  });

  final String label;
  final double value;
  final String uom;
  final bool isOverride;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  static String _fmt(double v) => _ActualWizardModalState._fmt(v);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: isOverride ? 0.6 : 0.3),
                width: isOverride ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOverride) ...[
                      Icon(Icons.push_pin, size: 11, color: color),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      '${_fmt(value)} $uom',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.edit_outlined, size: 11, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (onReset != null)
          IconButton(
            tooltip: 'Khôi phục',
            onPressed: onReset,
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _LineQtyModal extends StatefulWidget {
  const _LineQtyModal({required this.line, required this.initialQty});

  final ActualWizardLine line;
  final double initialQty;

  @override
  State<_LineQtyModal> createState() => _LineQtyModalState();
}

class _LineQtyModalState extends State<_LineQtyModal> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.initialQty > 0
        ? _ActualWizardModalState._fmt(widget.initialQty)
        : '';
  }

  double get _qty => double.tryParse(_text) ?? 0;

  String? _validate() {
    if (_qty < 0) return 'Số lượng không hợp lệ';
    if (_qty > widget.line.remainQty + 0.0001) {
      return 'Vượt quá còn lại '
          '(${_ActualWizardModalState._fmt(widget.line.remainQty)} ${widget.line.uom})';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final err = _validate();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune,
                      color: AppColors.warning, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sửa số lượng tiêu hao',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          line.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Get.back<double>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lot: ${line.lotName}  ·  Còn: '
                        '${_ActualWizardModalState._fmt(line.remainQty)} ${line.uom}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Numpad(
                value: _text,
                onChanged: (v) => setState(() => _text = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _text = _ActualWizardModalState._fmt(line.remainQty),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(
                    'Lấy hết ${_ActualWizardModalState._fmt(line.remainQty)}',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              if (err != null && _text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          err,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back<double>(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, AppSpacing.buttonHeight),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: err != null
                        ? null
                        : () => Get.back<double>(result: _qty),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Lưu'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, AppSpacing.buttonHeight),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineLossModal extends StatefulWidget {
  const _LineLossModal({required this.line, required this.initialQty});

  final ActualWizardLine line;
  final double initialQty;

  @override
  State<_LineLossModal> createState() => _LineLossModalState();
}

class _LineLossModalState extends State<_LineLossModal> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.initialQty > 0
        ? _ActualWizardModalState._fmt(widget.initialQty)
        : '';
  }

  double get _qty => double.tryParse(_text) ?? 0;

  String? _validate() {
    if (_qty < 0) return 'Số lượng không hợp lệ';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final err = _validate();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.broken_image_outlined,
                      color: AppColors.error, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hao hụt khác',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          line.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Get.back<double>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Text(
                  'Lot: ${line.lotName}  ·  Đơn vị: ${line.uom}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Numpad(
                value: _text,
                onChanged: (v) => setState(() => _text = v),
              ),
              if (err != null && _text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          err,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back<double>(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, AppSpacing.buttonHeight),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: err != null
                        ? null
                        : () => Get.back<double>(result: _qty),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Lưu'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, AppSpacing.buttonHeight),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
