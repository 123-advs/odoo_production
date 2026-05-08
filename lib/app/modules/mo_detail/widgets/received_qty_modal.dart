import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/mo_item_model.dart';
import '../../../widgets/numpad.dart';

class ReceivedQtyModal extends StatefulWidget {
  const ReceivedQtyModal({super.key, required this.item});

  final MoItemModel item;

  @override
  State<ReceivedQtyModal> createState() => _ReceivedQtyModalState();
}

class _ReceivedQtyModalState extends State<ReceivedQtyModal> {
  late String _qtyText;

  @override
  void initState() {
    super.initState();
    _qtyText = widget.item.receivedQty > 0
        ? _fmt(widget.item.receivedQty)
        : '';
  }

  double get _qty => double.tryParse(_qtyText) ?? 0;

  String? _validate() {
    if (_qty <= 0) return 'Số lượng phải lớn hơn 0';
    if (_qty > widget.item.stockQty + 0.0001) {
      return 'Vượt quá tồn kho (${_fmt(widget.item.stockQty)} ${widget.item.uom})';
    }
    return null;
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final err = _validate();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số lượng nhận',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.productName,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lot: ${item.lotName}  ·  Tồn kho: '
                        '${_fmt(item.stockQty)} ${item.uom}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Numpad(
                value: _qtyText,
                onChanged: (v) => setState(() => _qtyText = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Quick action: lấy hết tồn kho.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                      () => _qtyText = _fmt(item.stockQty)),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text('Lấy tất cả ${_fmt(item.stockQty)}'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              if (err != null && _qtyText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: AppColors.error),
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
