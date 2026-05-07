import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/issue_model.dart';

/// Modal for picking a `standard.issue` reason before submitting an OEE
/// wizard call (start or pause). Pops with the chosen [IssueModel] or
/// `null` on cancel.
///
/// `mode` chỉ ảnh hưởng vẻ ngoài (icon + title + nút xác nhận); cùng dùng
/// chung 1 RPC `submitOeeWizard`. Issues thì caller fetch riêng theo
/// `operating_status`: `on` cho start, `off` cho pause.
enum OeeMode { start, pause }

class OeeIssueModal extends StatefulWidget {
  const OeeIssueModal({
    super.key,
    required this.workorderName,
    required this.issues,
    this.mode = OeeMode.pause,
  });

  final String workorderName;
  final List<IssueModel> issues;
  final OeeMode mode;

  @override
  State<OeeIssueModal> createState() => _OeeIssueModalState();
}

class _OeeIssueModalState extends State<OeeIssueModal> {
  IssueModel? _selected;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? widget.issues
        : widget.issues.where((i) {
            final q = _filter.toLowerCase();
            return i.code.toLowerCase().contains(q) ||
                i.name.toLowerCase().contains(q);
          }).toList();

    final isStart = widget.mode == OeeMode.start;
    final accent = isStart ? AppColors.success : AppColors.warning;
    final headerIcon = isStart
        ? Icons.play_circle_outline
        : Icons.pause_circle_outline;
    final title = isStart ? 'Bắt đầu công đoạn' : 'Báo cáo dừng máy';
    final hint =
        isStart ? 'Chọn trạng thái khi bắt đầu:' : 'Chọn lý do dừng:';
    final confirmIcon =
        isStart ? Icons.play_arrow_rounded : Icons.pause_rounded;
    final confirmLabel = isStart ? 'Bắt đầu' : 'Xác nhận dừng';

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(headerIcon, color: accent, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.workorderName,
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
                    onPressed: () => Get.back<IssueModel?>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                onChanged: (v) => setState(() => _filter = v),
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã hoặc tên',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: RadioGroup<int>(
                          groupValue: _selected?.id,
                          onChanged: (id) {
                            if (id == null) return;
                            setState(() => _selected = filtered
                                .firstWhere((it) => it.id == id));
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Divider(
                                height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) {
                              final issue = filtered[i];
                              return RadioListTile<int>(
                                title: Text(
                                  issue.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Mã: ${issue.code}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                value: issue.id,
                                activeColor: AppColors.primary,
                                selected: _selected?.id == issue.id,
                              );
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back<IssueModel?>(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, AppSpacing.buttonHeight),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () => Get.back<IssueModel?>(result: _selected),
                    icon: Icon(confirmIcon),
                    label: Text(confirmLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(180, AppSpacing.buttonHeight),
                      backgroundColor: accent,
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
            Icon(Icons.search_off_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Không tìm thấy lý do nào.\n'
              'Liên hệ quản trị viên để cấu hình standard.issue.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
