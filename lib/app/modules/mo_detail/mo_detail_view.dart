import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'mo_detail_controller.dart';
import 'widgets/documents_panel.dart';
import 'widgets/items_panel.dart';
import 'widgets/mo_header.dart';
import 'widgets/operations_panel.dart';
import 'widgets/timelogs_panel.dart';
import 'widgets/workorder_panel.dart';

class MoDetailView extends GetView<MoDetailController> {
  const MoDetailView({super.key});

  static const _tabs = [
    Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Vật tư'),
    Tab(icon: Icon(Icons.engineering_outlined), text: 'Công đoạn'),
    Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Sản lượng'),
    Tab(icon: Icon(Icons.pause_circle_outline), text: 'Dừng máy'),
    Tab(icon: Icon(Icons.attach_file_outlined), text: 'Tài liệu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.mo.value?.name ?? 'Chi tiết MO',
              style: const TextStyle(fontWeight: FontWeight.w700),
            )),
        actions: [
          // "Hoàn tất MO" sits in the AppBar so it's reachable from any
          // tab — not just Vật tư. Visible only when MO is `in_progress`.
          Obx(() {
            final mo = controller.mo.value;
            if (mo == null || !mo.isInProgress) {
              return const SizedBox.shrink();
            }
            final mutating = controller.isMutating.value;
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              child: FilledButton.icon(
                onPressed: mutating ? null : controller.completeMo,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Hoàn tất MO'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: controller.loadDetail,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.mo.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final err = controller.errorMessage.value;
          if (err != null && controller.mo.value == null) {
            return _ErrorState(message: err, onRetry: controller.loadDetail);
          }
          final mo = controller.mo.value;
          if (mo == null) return const SizedBox.shrink();
          return DefaultTabController(
            length: _tabs.length,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoHeader(mo: mo),
                  const SizedBox(height: AppSpacing.sm),
                  // Slim tab bar — no card wrapper, just a bottom border.
                  // Saves ~30dp compared to the elevated rounded version.
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: const TabBar(
                      tabs: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      dividerHeight: 0,
                      labelPadding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        ItemsPanel(),
                        WorkorderPanel(),
                        OperationsPanel(),
                        TimelogsPanel(),
                        DocumentsPanel(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
