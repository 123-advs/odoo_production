import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/production_model.dart';
import '../../../data/models/qc_form_model.dart';
import '../../../widgets/numpad.dart';

class QcFormResult {
  QcFormResult({
    required this.okQty,
    required this.ngQty,
    required this.checkListJson,
    required this.inspectionData,
  });

  final double okQty;
  final double ngQty;
  final List<Map<String, dynamic>> checkListJson;
  final Map<String, dynamic> inspectionData;
}

class QcFormModal extends StatefulWidget {
  const QcFormModal({
    super.key,
    required this.production,
    required this.form,
  });

  final ProductionModel production;
  final QcFormPreview form;

  @override
  State<QcFormModal> createState() => _QcFormModalState();
}

class _QcFormModalState extends State<QcFormModal> {
  late String _okText;
  String _ngText = '0';
  late final List<QcCheckItem> _items;

  @override
  void initState() {
    super.initState();

    _okText = _fmt(widget.production.actualQty);
    _items = widget.form.checkList;
  }

  double get _ok => double.tryParse(_okText) ?? 0;
  double get _ng => double.tryParse(_ngText) ?? 0;
  double get _total => _ok + _ng;
  bool get _totalMatches =>
      (_total - widget.production.actualQty).abs() < 0.0001;

  int get _unanswered => _items.where((i) => !i.isAnswered).length;

  bool get _canConfirm => _totalMatches;

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: AppSpacing.sm),
              _productionInfo(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 4, child: _numpadColumn()),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(flex: 6, child: _checkListPane()),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _numpadColumn(),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 400,
                            child: _checkListPane(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _summaryAndActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Sub widgets ---------------------------------------------------

  Widget _header() {
    final p = widget.production;
    return Row(
      children: [
        Icon(
          p.isLastLevel
              ? Icons.verified_outlined
              : Icons.fact_check_outlined,
          color: AppColors.primary,
          size: 26,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kiểm tra chất lượng — ${p.qcKind}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.form.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Get.back<QcFormResult?>(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _productionInfo() {
    final p = widget.production;
    final f = widget.form;
    final chips = <Widget>[
      _InfoChip(
        icon: Icons.qr_code_2_outlined,
        label: 'Lot',
        value: p.lotName,
      ),
      _InfoChip(
        icon: Icons.scale_outlined,
        label: 'Sản lượng',
        value: '${_fmt(p.actualQty)} ${f.qtyUom ?? ""}',
      ),
      if (f.lineNo != null)
        _InfoChip(
          icon: Icons.precision_manufacturing_outlined,
          label: 'Dây chuyền',
          value: f.lineNo!,
        ),
      if (f.process != null && f.process!.isNotEmpty)
        _InfoChip(
          icon: Icons.account_tree_outlined,
          label: 'Process',
          value: f.process!,
        ),
      if (f.materialCode != null)
        _InfoChip(
          icon: Icons.tag,
          label: 'Mã',
          value: f.materialCode!,
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _numpadColumn() {
    return Row(
      children: [
        Expanded(
          child: _qtyCol(
            label: 'OK',
            color: AppColors.success,
            value: _okText,
            onChanged: (v) => setState(() => _okText = v),
            autofocus: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _qtyCol(
            label: 'NG',
            color: AppColors.error,
            value: _ngText,
            onChanged: (v) => setState(() => _ngText = v),
            autofocus: false,
          ),
        ),
      ],
    );
  }

  Widget _qtyCol({
    required String label,
    required Color color,
    required String value,
    required ValueChanged<String> onChanged,
    required bool autofocus,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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

  Widget _checkListPane() {
    if (_items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Biểu mẫu này không có hạng mục kiểm tra nào.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Title bar (above column headers).
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hạng mục kiểm tra',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _CountChip(
                  label: 'Đã chấm',
                  value:
                      '${_items.where((i) => i.isAnswered).length}/${_items.length}',
                  color: _unanswered == 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ),
          const _CheckListHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _CheckTableRow(
                item: _items[i],
                index: i + 1,
                striped: i.isOdd,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryAndActions() {
    final color = _totalMatches ? AppColors.success : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
              Icon(
                _totalMatches
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Tổng: ${_fmt(_ok)} OK + ${_fmt(_ng)} NG = ${_fmt(_total)}'
                  '  ·  Cần ${_fmt(widget.production.actualQty)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (_unanswered > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Còn $_unanswered hạng mục chưa chấm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Get.back<QcFormResult?>(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, AppSpacing.buttonHeight),
              ),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _canConfirm
                  ? () {
                      final checkListJson =
                          _items.map((i) => i.toJson()).toList();
                      final inspection = widget.form.toInspectionData(
                        okQty: _ok,
                        ngQty: _ng,
                        checkListJson: checkListJson,
                      );
                      Get.back<QcFormResult?>(
                        result: QcFormResult(
                          okQty: _ok,
                          ngQty: _ng,
                          checkListJson: checkListJson,
                          inspectionData: inspection,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.check_rounded),
              label:
                  Text('Xác nhận ${widget.production.qcKind}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, AppSpacing.buttonHeight),
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColSpec {
  const _ColSpec({required this.flex, this.fixedWidth, required this.title});

  final int flex;
  final double? fixedWidth;
  final String title;

  static const stt = _ColSpec(flex: 0, fixedWidth: 36, title: 'STT');
  static const hangMuc = _ColSpec(flex: 5, title: 'Hạng mục');
  static const standard = _ColSpec(flex: 3, title: 'Tiêu chuẩn');
  static const result = _ColSpec(flex: 3, title: 'Kết quả');
  static const note = _ColSpec(flex: 0, fixedWidth: 36, title: '');
}

Widget _cell({
  required _ColSpec spec,
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  final wrapped = Padding(
    padding: padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
    child: child,
  );
  if (spec.fixedWidth != null) {
    return SizedBox(width: spec.fixedWidth, child: wrapped);
  }
  return Expanded(flex: spec.flex, child: wrapped);
}

class _CheckListHeader extends StatelessWidget {
  const _CheckListHeader();

  @override
  Widget build(BuildContext context) {
    Widget headerCell(_ColSpec spec, {TextAlign align = TextAlign.left}) {
      return _cell(
        spec: spec,
        child: Text(
          spec.title,
          textAlign: align,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          headerCell(_ColSpec.stt, align: TextAlign.center),
          headerCell(_ColSpec.hangMuc),
          headerCell(_ColSpec.standard),
          headerCell(_ColSpec.result, align: TextAlign.center),
          headerCell(_ColSpec.note),
        ],
      ),
    );
  }
}

class _CheckTableRow extends StatefulWidget {
  const _CheckTableRow({
    required this.item,
    required this.index,
    required this.striped,
    required this.onChanged,
  });

  final QcCheckItem item;
  final int index;
  final bool striped;
  final VoidCallback onChanged;

  @override
  State<_CheckTableRow> createState() => _CheckTableRowState();
}

class _CheckTableRowState extends State<_CheckTableRow> {
  bool _showRemark = false;
  late final TextEditingController _remarkCtrl;

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController(text: widget.item.remark);
    _showRemark = widget.item.remark.isNotEmpty;
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _setResult(String r) {
    setState(() => widget.item.result = r);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final answered = item.isAnswered;
    Color leftAccent = Colors.transparent;
    if (item.isOk) leftAccent = AppColors.success;
    if (item.isNg) leftAccent = AppColors.error;

    final stripedBg = widget.striped
        ? AppColors.background.withValues(alpha: 0.5)
        : AppColors.surface;
    final tintBg = answered && leftAccent != Colors.transparent
        ? leftAccent.withValues(alpha: 0.04)
        : stripedBg;

    return Container(
      decoration: BoxDecoration(
        color: tintBg,
        border: Border(
          left: BorderSide(
            color: leftAccent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _cell(
                  spec: _ColSpec.stt,
                  child: Text(
                    '${widget.index}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                _cell(
                  spec: _ColSpec.hangMuc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.qcProcess.isEmpty
                            ? '(Không tên)'
                            : item.qcProcess,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.qcType.isNotEmpty ||
                          item.method.isNotEmpty ||
                          item.frequency.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (item.qcType.isNotEmpty) '[${item.qcType}]',
                            if (item.method.isNotEmpty) item.method,
                            if (item.frequency.isNotEmpty) item.frequency,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                _cell(
                  spec: _ColSpec.standard,
                  child: Text(
                    item.qcCode.isEmpty && item.standard.isEmpty
                        ? '—'
                        : [
                            if (item.qcCode.isNotEmpty) item.qcCode,
                            if (item.standard.isNotEmpty &&
                                item.standard != item.qcCode)
                              item.standard,
                          ].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _cell(
                  spec: _ColSpec.result,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  child: Center(
                    child: item.isOkNg
                        ? _OkNgPair(
                            selected: item.result,
                            onChanged: _setResult,
                          )
                        : _ValueInput(
                            isNumber: item.isNumber,
                            initialValue: item.result,
                            onChanged: _setResult,
                          ),
                  ),
                ),
                _cell(
                  spec: _ColSpec.note,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    tooltip: 'Ghi chú',
                    onPressed: () =>
                        setState(() => _showRemark = !_showRemark),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: Icon(
                      _showRemark
                          ? Icons.notes
                          : Icons.note_add_outlined,
                      color: item.remark.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showRemark)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                36 + AppSpacing.sm,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _remarkCtrl,
                onChanged: (v) {
                  widget.item.remark = v;
                  widget.onChanged();
                },
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OkNgPair extends StatelessWidget {
  const _OkNgPair({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OkNgButton(
          label: 'OK',
          color: AppColors.success,
          selected: selected.toLowerCase() == 'ok',
          onTap: () => onChanged('ok'),
        ),
        const SizedBox(width: 6),
        _OkNgButton(
          label: 'NG',
          color: AppColors.error,
          selected: selected.toLowerCase() == 'ng',
          onTap: () => onChanged('ng'),
        ),
      ],
    );
  }
}

class _OkNgButton extends StatelessWidget {
  const _OkNgButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 56,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.4),
              width: selected ? 0 : 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueInput extends StatefulWidget {
  const _ValueInput({
    required this.isNumber,
    required this.initialValue,
    required this.onChanged,
  });

  final bool isNumber;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_ValueInput> createState() => _ValueInputState();
}

class _ValueInputState extends State<_ValueInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = _ctrl.text.trim().isNotEmpty;
    final accent = filled ? AppColors.primary : AppColors.textMuted;
    return SizedBox(
      width: 140,
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        keyboardType: widget.isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.isNumber ? 'Nhập số' : 'Nhập giá trị',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: accent.withValues(alpha: filled ? 0.5 : 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
