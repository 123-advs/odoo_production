import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/mo_detail_model.dart';
import '../../../data/models/mo_item_model.dart';
import '../../../widgets/scan_input.dart';
import '../mo_detail_controller.dart';

class ItemsPanel extends GetView<MoDetailController> {
  const ItemsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mo = controller.mo.value;
      if (mo == null) return const SizedBox.shrink();
      // Only allow scanning once MO is started — drafts must press
      // "Bắt đầu MO" first; done/cancel are read-only.
      final canScan = mo.isInProgress;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canScan) ...[
            ScanInput(
              label: 'Quét lot vật tư',
              onScanned: controller.scanLot,
              enabled: !controller.isMutating.value,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(child: _itemsTable(mo)),
          const SizedBox(height: AppSpacing.sm),
          _bottomActions(mo),
        ],
      );
    });
  }

  Widget _itemsTable(MoDetailModel mo) {
    final items = controller.filteredItems;
    if (items.isEmpty) {
      // Wrap in a scroll view so the column never overflows when the
      // available height shrinks (e.g. on smaller windows or when the
      // scan input + bottom buttons leave little room).
      final hasOtherLineItems = mo.items.isNotEmpty;
      final wcName = controller.workcenterName ?? '';
      final message = hasOtherLineItems
          ? 'Dây chuyền $wcName chưa có vật tư.\n'
              'MO đang có vật tư cho dây chuyền khác.'
          : 'Chưa có vật tư nào. Quét lot ở phía trên để thêm.';
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 36, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) => _ItemRow(item: items[i]),
      ),
    );
  }

  Widget _bottomActions(MoDetailModel mo) {
    return Obx(() {
      final mutating = controller.isMutating.value;
      final selectedCount = controller.selectedItemIds.length;
      final canReturn = controller.hasReturnableItems;
      return Row(
        children: [
          if (mo.canConfirmMo)
            Expanded(
              child: FilledButton.icon(
                onPressed: mutating ? null : controller.confirmMo,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu MO'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          if (mo.canConfirmMo) const SizedBox(width: AppSpacing.md),
          if (canReturn) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    mutating ? null : controller.openReturnWizard,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Trả vật tư'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  foregroundColor: AppColors.warning,
                  side:
                      const BorderSide(color: AppColors.warning, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: mutating || selectedCount == 0
                  ? null
                  : controller.confirmSelectedItems,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                selectedCount == 0
                    ? 'Xác nhận vật tư'
                    : 'Xác nhận ($selectedCount)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MoItemModel item;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoDetailController>();
    return Obx(() {
      final selected = c.selectedItemIds.contains(item.id);
      final disabled = !item.isDraft;
      return InkWell(
        onTap: disabled ? null : () => c.toggleItem(item.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: disabled
                    ? null
                    : (v) => c.toggleItem(item.id),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Lot: ${item.lotName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: _QtyCell(item: item),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ItemStateChip(state: item.state),
                ),
              ),
              IconButton(
                tooltip: item.isDraft ? 'Xoá dòng' : 'Đã xác nhận, không xoá được',
                onPressed: item.isDraft && !c.isMutating.value
                    ? () => c.deleteItem(item.id)
                    : null,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Tappable qty cell. Mirrors the Odoo backend layout — three small
/// numbers (Tồn / Còn / Nhận) followed by the UoM. For draft items the
/// whole cell is wrapped in a colored container with an edit icon so the
/// worker knows it's tappable; tapping opens the received-qty editor.
///
/// We use a stand-alone GestureDetector with `HitTestBehavior.opaque` so
/// the tap doesn't bubble up and toggle the row checkbox.
class _QtyCell extends StatelessWidget {
  const _QtyCell({required this.item});

  final MoItemModel item;

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    if (!item.isDraft) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _statRow(emphasiseReceived: false),
      );
    }
    final c = Get.find<MoDetailController>();
    final needsQty = item.receivedQty <= 0;
    final accent = needsQty ? AppColors.warning : AppColors.primary;
    return Obx(() {
      final disabled = c.isMutating.value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => c.editItemQty(item),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: needsQty ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: accent.withValues(alpha: needsQty ? 0.5 : 0.3),
              width: needsQty ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow(emphasiseReceived: true, receivedColor: accent),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 14, color: accent),
            ],
          ),
        ),
      );
    });
  }

  Widget _statRow({
    required bool emphasiseReceived,
    Color? receivedColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Stat(label: 'Tồn', value: _fmt(item.stockQty)),
        const SizedBox(width: 10),
        _Stat(label: 'Còn', value: _fmt(item.remainQty)),
        const SizedBox(width: 10),
        _Stat(
          label: 'Nhận',
          value: _fmt(item.receivedQty),
          valueColor:
              emphasiseReceived ? receivedColor : AppColors.textPrimary,
          bold: emphasiseReceived,
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            item.uom,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ItemStateChip extends StatelessWidget {
  const _ItemStateChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      'confirm' => (AppColors.success, 'Đã xác nhận'),
      _ => (AppColors.accent, 'Mới'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
