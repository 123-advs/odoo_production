import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/return_wizard_model.dart';
import '../../../widgets/numpad.dart';

class ReturnWizardResult {
  ReturnWizardResult({required this.returnQtyByLineId});

  final Map<int, double> returnQtyByLineId;
}

class ReturnWizardModal extends StatefulWidget {
  const ReturnWizardModal({
    super.key,
    required this.wizard,
    required this.moName,
  });

  final ReturnWizardModel wizard;
  final String moName;

  @override
  State<ReturnWizardModal> createState() => _ReturnWizardModalState();
}

class _ReturnWizardModalState extends State<ReturnWizardModal> {
  late final Map<int, double> _returnQty;

  @override
  void initState() {
    super.initState();
    _returnQty = <int, double>{
      for (final l in widget.wizard.lines) l.id: l.returnQty,
    };
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  double get _totalReturn =>
      _returnQty.values.fold<double>(0, (a, b) => a + b);

  bool get _canConfirm => _totalReturn > 0;

  Future<void> _editLine(ReturnWizardLine line) async {
    final qty = await Get.dialog<double>(
      _ReturnQtyModal(line: line, initialQty: _returnQty[line.id] ?? 0),
      barrierDismissible: false,
    );
    if (qty == null || qty < 0) return;
    setState(() => _returnQty[line.id] = qty);
  }

  void _setAllToRemain() {
    setState(() {
      for (final l in widget.wizard.lines) {
        _returnQty[l.id] = l.remainQty;
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (final id in _returnQty.keys.toList()) {
        _returnQty[id] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: AppSpacing.sm),
              _quickActions(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _table()),
              const SizedBox(height: AppSpacing.sm),
              _summary(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back<ReturnWizardResult?>(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, AppSpacing.buttonHeight),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _canConfirm
                        ? () => Get.back<ReturnWizardResult?>(
                              result: ReturnWizardResult(
                                returnQtyByLineId: Map.of(_returnQty),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Trả vật tư'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(180, AppSpacing.buttonHeight),
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

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.replay_circle_filled_outlined,
            color: AppColors.warning, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trả vật tư thừa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.moName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Get.back<ReturnWizardResult?>(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _setAllToRemain,
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Chọn trả hết'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('Bỏ chọn'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _table() {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1.2),
              ),
            ),
            child: const Row(
              children: [
                _Hdr(width: 36, text: 'STT', center: true),
                _HdrFlex(flex: 5, text: 'Vật tư'),
                _HdrFlex(flex: 4, text: 'Đã nhận / Đã dùng'),
                _HdrFlex(flex: 3, text: 'Còn dư', center: true),
                _HdrFlex(flex: 3, text: 'Trả', center: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.wizard.lines.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final line = widget.wizard.lines[i];
                final qty = _returnQty[line.id] ?? 0;
                return _ReturnRow(
                  index: i + 1,
                  line: line,
                  returnQty: qty,
                  striped: i.isOdd,
                  onTap: () => _editLine(line),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final color = _canConfirm ? AppColors.warning : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.replay, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _canConfirm
                  ? 'Tổng trả: ${_fmt(_totalReturn)}'
                  : 'Hãy nhập số lượng trả ở ít nhất 1 dòng',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({
    required this.index,
    required this.line,
    required this.returnQty,
    required this.striped,
    required this.onTap,
  });

  final int index;
  final ReturnWizardLine line;
  final double returnQty;
  final bool striped;
  final VoidCallback onTap;

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final hasReturn = returnQty > 0;
    final overflow = returnQty > line.remainQty + 0.0001;
    final accent = overflow
        ? AppColors.error
        : hasReturn
            ? AppColors.warning
            : AppColors.textMuted;
    return Container(
      decoration: BoxDecoration(
        color: hasReturn
            ? AppColors.warning.withValues(alpha: 0.04)
            : (striped
                ? AppColors.background.withValues(alpha: 0.5)
                : AppColors.surface),
        border: Border(
          left: BorderSide(
            color: hasReturn ? AppColors.warning : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      line.productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lot: ${line.lotName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  '${_fmt(line.receivedQty)} / ${_fmt(line.totalUsingQty)} ${line.uom}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  '${_fmt(line.remainQty)} ${line.uom}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Center(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: hasReturn ? 0.6 : 0.3),
                          width: hasReturn ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_fmt(returnQty)} ${line.uom}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              size: 13, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  const _Hdr({required this.width, required this.text, this.center = false});

  final double width;
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _HdrFlex extends StatelessWidget {
  const _HdrFlex({required this.flex, required this.text, this.center = false});

  final int flex;
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _ReturnQtyModal extends StatefulWidget {
  const _ReturnQtyModal({required this.line, required this.initialQty});

  final ReturnWizardLine line;
  final double initialQty;

  @override
  State<_ReturnQtyModal> createState() => _ReturnQtyModalState();
}

class _ReturnQtyModalState extends State<_ReturnQtyModal> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text =
        widget.initialQty > 0 ? _fmt(widget.initialQty) : '';
  }

  double get _qty => double.tryParse(_text) ?? 0;

  String? _validate() {
    if (_qty < 0) return 'Số lượng không hợp lệ';
    if (_qty > widget.line.remainQty + 0.0001) {
      return 'Vượt quá còn dư '
          '(${_fmt(widget.line.remainQty)} ${widget.line.uom})';
    }
    return null;
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
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
                  const Icon(Icons.replay_circle_filled_outlined,
                      color: AppColors.warning, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số lượng trả',
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
                  'Lot: ${line.lotName}  ·  Còn dư: '
                  '${_fmt(line.remainQty)} ${line.uom}',
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
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                      () => _text = _fmt(line.remainQty)),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text('Trả hết ${_fmt(line.remainQty)}'),
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
