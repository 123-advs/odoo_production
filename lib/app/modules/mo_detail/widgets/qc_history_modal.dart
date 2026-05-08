import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/production_model.dart';
import '../../../data/models/qc_form_model.dart';

class QcHistoryModal extends StatefulWidget {
  const QcHistoryModal({
    super.key,
    required this.production,
    required this.records,
  });

  final ProductionModel production;
  final List<QcHistoryRecord> records;

  @override
  State<QcHistoryModal> createState() => _QcHistoryModalState();
}

class _QcHistoryModalState extends State<QcHistoryModal> {
  int _idx = 0;

  static final _dt = DateFormat('dd/MM/yyyy HH:mm:ss');

  static String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  QcHistoryRecord get _rec => widget.records[_idx];

  @override
  Widget build(BuildContext context) {
    final p = widget.production;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch sử kiểm tra ${p.qcKind}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Lot: ${p.lotName}',
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
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.records.length > 1) _historyTabs(),
              if (widget.records.length > 1)
                const SizedBox(height: AppSpacing.sm),
              _summary(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _checkList()),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Get.back<void>(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, AppSpacing.buttonHeight),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.records.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final r = widget.records[i];
          final selected = i == _idx;
          return InkWell(
            onTap: () => setState(() => _idx = i),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                r.checkDate == null ? '#${r.id}' : _dt.format(r.checkDate!),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summary() {
    final r = _rec;
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
        spacing: AppSpacing.lg,
        runSpacing: 6,
        children: [
          _SummaryStat(label: 'Form', value: r.name.isEmpty ? '—' : r.name),
          if (r.checkDate != null)
            _SummaryStat(
                label: 'Ngày kiểm', value: _dt.format(r.checkDate!)),
          if (r.staffName != null)
            _SummaryStat(label: 'Người kiểm', value: r.staffName!),
          _SummaryStat(
            label: 'OK',
            value: _fmt(r.okQty),
            color: AppColors.success,
          ),
          _SummaryStat(
            label: 'NG',
            value: _fmt(r.ngQty),
            color: AppColors.error,
          ),
          if (r.qtySampling != null)
            _SummaryStat(label: 'Mẫu kiểm', value: _fmt(r.qtySampling)),
          if (r.defectRatio != null)
            _SummaryStat(
              label: 'Defect %',
              value: _fmt(r.defectRatio),
              color: (r.defectRatio ?? 0) > 0
                  ? AppColors.warning
                  : AppColors.textPrimary,
            ),
          if (r.overallResult != null)
            _SummaryStat(
              label: 'Kết quả',
              value: r.overallResult!,
              color: r.overallResult!.toUpperCase() == 'NG'
                  ? AppColors.error
                  : AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _checkList() {
    final items = _rec.checkList;
    if (items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Lần kiểm tra này không có chi tiết hạng mục.',
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
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1.2),
              ),
            ),
            child: const Row(
              children: [
                _HeaderCell(width: 36, text: 'STT', center: true),
                _HeaderCellExp(flex: 5, text: 'Hạng mục'),
                _HeaderCellExp(flex: 3, text: 'Tiêu chuẩn'),
                _HeaderCellExp(flex: 3, text: 'Kết quả', center: true),
                _HeaderCellExp(flex: 3, text: 'Ghi chú'),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _HistoryRow(
                item: items[i],
                index: i + 1,
                striped: i.isOdd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.width,
    required this.text,
    this.center = false,
  });

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

class _HeaderCellExp extends StatelessWidget {
  const _HeaderCellExp({
    required this.flex,
    required this.text,
    this.center = false,
  });

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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.index,
    required this.striped,
  });

  final QcCheckItem item;
  final int index;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    Color leftAccent = Colors.transparent;
    if (item.isOk) leftAccent = AppColors.success;
    if (item.isNg) leftAccent = AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: striped
            ? AppColors.background.withValues(alpha: 0.5)
            : AppColors.surface,
        border: Border(left: BorderSide(color: leftAccent, width: 3)),
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
                      item.qcProcess.isEmpty ? '(Không tên)' : item.qcProcess,
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
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            ),
            Expanded(
              flex: 3,
              child: Center(child: _ResultChip(item: item)),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  item.remark.isEmpty ? '—' : item.remark,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.remark.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.item});

  final QcCheckItem item;

  @override
  Widget build(BuildContext context) {
    final value = item.result.trim();
    final empty = value.isEmpty;
    Color color;
    String text;
    if (empty) {
      color = AppColors.textMuted;
      text = '—';
    } else if (value.toLowerCase() == 'ok') {
      color = AppColors.success;
      text = 'OK';
    } else if (value.toLowerCase() == 'ng') {
      color = AppColors.error;
      text = 'NG';
    } else {
      // text / number value — display as-is, primary accent
      color = AppColors.primary;
      text = value;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      constraints: const BoxConstraints(minWidth: 48),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
