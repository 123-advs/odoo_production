import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/mo_model.dart';
import '../../routes/app_routes.dart';
import 'mo_list_controller.dart';
import 'widgets/mo_detail_placeholder.dart';
import 'widgets/mo_list_card.dart';

class MoListView extends GetView<MoListController> {
  const MoListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          controller.headerTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (controller.userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Center(
                child: Text(
                  controller.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Đổi dây chuyền',
            onPressed: controller.changeWorkcenter,
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: controller.loadMos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            if (wide) {
              return Row(
                children: [
                  SizedBox(
                    width: constraints.maxWidth * 0.42,
                    child: _ListPane(onTap: _openDetail),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(
                    child: Obx(() {
                      final mo = controller.selectedMo;
                      return MoDetailPlaceholder(
                        mo: mo,
                        onOpen: mo == null ? null : () => _openDetail(mo),
                      );
                    }),
                  ),
                ],
              );
            }
            return _ListPane(onTap: _openDetail);
          },
        ),
      ),
    );
  }

  void _openDetail(MoModel mo) {
    controller.selectMo(mo.id);
    Get.toNamed(
      AppRoutes.moDetail,
      parameters: {'id': mo.id.toString()},
    )?.then((_) => controller.loadMos());
  }
}

class _ListPane extends StatelessWidget {
  const _ListPane({required this.onTap});

  final void Function(MoModel) onTap;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoListController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SearchBox(),
        const _FilterBar(),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: Obx(() {
            if (c.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final err = c.errorMessage.value;
            if (err != null) {
              return _ErrorState(message: err, onRetry: c.loadMos);
            }
            if (c.mos.isEmpty) return const _EmptyState();
            final list = c.filteredMos;
            if (list.isEmpty) {
              return _NoMatchState(onReset: c.clearSearch);
            }
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final mo = list[i];
                return Obx(() => MoListCard(
                      mo: mo,
                      selected: c.selectedId.value == mo.id,
                      onTap: () => onTap(mo),
                    ));
              },
            );
          }),
        ),
      ],
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox();

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final c = Get.find<MoListController>();
    _ctrl = TextEditingController(text: c.searchQuery.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoListController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: c.setSearchQuery,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm MO / sản phẩm / mã',
          isDense: true,
          prefixIcon: const Icon(Icons.search,
              size: 20, color: AppColors.textMuted),
          suffixIcon: Obx(() {
            if (c.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Xoá',
              onPressed: () {
                _ctrl.clear();
                c.clearSearch();
              },
              icon: const Icon(Icons.close,
                  size: 18, color: AppColors.textMuted),
            );
          }),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Không tìm thấy MO nào khớp',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Bỏ tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoListController>();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
              children: MoStateFilter.values.map((f) {
                final active = c.filter.value == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: active,
                    onSelected: (_) => c.setFilter(f),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color:
                          active ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            )),
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
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Không có MO nào trong dây chuyền này',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
