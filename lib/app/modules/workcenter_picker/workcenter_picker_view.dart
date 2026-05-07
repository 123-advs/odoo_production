import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/workcenter_model.dart';
import 'workcenter_picker_controller.dart';

class WorkcenterPickerView extends GetView<WorkcenterPickerController> {
  const WorkcenterPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          controller.userName.isEmpty
              ? 'Chọn dây chuyền'
              : 'Xin chào, ${controller.userName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: controller.loadWorkcenters,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn dây chuyền cho ca làm hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Obx(() {
                final total = controller.workcenters.length;
                final shown = controller.filteredWorkcenters.length;
                final hasFilter = controller.searchQuery.value.isNotEmpty ||
                    controller.selectedProcess.value != null;
                return Text(
                  hasFilter
                      ? 'Hiển thị $shown / $total dây chuyền'
                      : 'Bấm vào dây chuyền của bạn để bắt đầu ca',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              const _SearchBox(),
              const SizedBox(height: AppSpacing.sm),
              const _ProcessFilterBar(),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: Obx(_buildBody)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final err = controller.errorMessage.value;
    if (err != null) {
      return _ErrorState(message: err, onRetry: controller.loadWorkcenters);
    }
    if (controller.workcenters.isEmpty) {
      return const _EmptyState();
    }
    final list = controller.filteredWorkcenters;
    if (list.isEmpty) {
      return _NoMatchState(onReset: controller.resetFilters);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tighter grid: aim for ~280-340dp wide cards. Aspect 1.3
        // (slightly wide-rectangle) — fits the hero-number layout cleanly.
        const targetWidth = 320.0;
        final cols = (constraints.maxWidth / targetWidth).floor().clamp(1, 6);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.3,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) => _WorkcenterCard(
            wc: list[i],
            onTap: () => controller.select(list[i]),
          ),
        );
      },
    );
  }
}

/// Single-line search input. Filters the loaded list in-memory — no extra
/// RPC, so feedback is instant.
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
    final c = Get.find<WorkcenterPickerController>();
    _ctrl = TextEditingController(text: c.searchQuery.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WorkcenterPickerController>();
    return TextField(
      controller: _ctrl,
      onChanged: c.setSearchQuery,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Tìm theo tên / mã / process',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: Obx(() {
          if (c.searchQuery.value.isEmpty) return const SizedBox.shrink();
          return IconButton(
            tooltip: 'Xoá',
            onPressed: () {
              _ctrl.clear();
              c.clearSearch();
            },
            icon: const Icon(Icons.close, color: AppColors.textMuted),
          );
        }),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
      ),
    );
  }
}

/// Horizontal scrollable row of process chips. First chip is "Tất cả"
/// (resets the process filter). Each process chip uses the same colour
/// as the corresponding card stripe — so visual grouping carries over.
class _ProcessFilterBar extends StatelessWidget {
  const _ProcessFilterBar();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WorkcenterPickerController>();
    return Obx(() {
      final processes = c.uniqueProcesses;
      if (processes.isEmpty) return const SizedBox.shrink();
      final selected = c.selectedProcess.value;
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: processes.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _FilterChip(
                label: 'Tất cả',
                color: AppColors.textSecondary,
                selected: selected == null,
                onTap: () => c.toggleProcess(null),
              );
            }
            final name = processes[i - 1];
            return _FilterChip(
              label: name,
              color: _processColor(name),
              selected: selected == name,
              onTap: () => c.toggleProcess(name),
            );
          },
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    final bg = selected
        ? color.withValues(alpha: 0.15)
        : AppColors.surface;
    final border = selected ? color : AppColors.divider;
    final fg = selected ? color : AppColors.textSecondary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single workcenter card. Visual hierarchy:
///   1. Process chip at top (each process gets a deterministic colour
///      so cards group visually without explicit section headers).
///   2. Hero "name" — big primary-coloured wordmark, the focal point.
///   3. Code as muted subtitle.
///   4. "Vào ca →" footer giving a clear tap affordance.
class _WorkcenterCard extends StatefulWidget {
  const _WorkcenterCard({required this.wc, required this.onTap});

  final WorkcenterModel wc;
  final VoidCallback onTap;

  @override
  State<_WorkcenterCard> createState() => _WorkcenterCardState();
}

class _WorkcenterCardState extends State<_WorkcenterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final processColor = _processColor(widget.wc.processName);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: _hovered
                ? processColor.withValues(alpha: 0.6)
                : AppColors.divider,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? processColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 18 : 8,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            splashColor: processColor.withValues(alpha: 0.10),
            highlightColor: processColor.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Watermark icon — bottom-right, low opacity, decorative.
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 120,
                    color: processColor.withValues(alpha: 0.06),
                  ),
                ),
                // Top-left vertical accent stripe — colour from process.
                Positioned(
                  left: 0,
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: processColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md + 4,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProcessChip(
                        name: widget.wc.processName ?? 'Chưa gán Process',
                        color: processColor,
                        muted: widget.wc.processName == null,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Dây chuyền',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.wc.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.05,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (widget.wc.code != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tag,
                                    size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    widget.wc.code!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _hovered
                                  ? processColor
                                  : AppColors.textSecondary,
                            ),
                            child: const Text('Vào ca'),
                          ),
                          const SizedBox(width: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            transform: Matrix4.translationValues(
                              _hovered ? 4 : 0,
                              0,
                              0,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: _hovered
                                  ? processColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped process tag at the top of the card.
class _ProcessChip extends StatelessWidget {
  const _ProcessChip({
    required this.name,
    required this.color,
    required this.muted,
  });

  final String name;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: muted ? 0.2 : 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted ? AppColors.textMuted : color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-curated palette of accent hues. A process name is hashed into one
/// of these — same process always gets the same colour, so cards on the
/// grid group visually without needing explicit section headers.
const _processPalette = <Color>[
  Color(0xFF0EA5E9), // sky-500
  Color(0xFF8B5CF6), // violet-500
  Color(0xFF14B8A6), // teal-500
  Color(0xFFF97316), // orange-500
  Color(0xFFEC4899), // pink-500
  Color(0xFF6366F1), // indigo-500
  Color(0xFF84CC16), // lime-500
  Color(0xFFF59E0B), // amber-500
  Color(0xFF06B6D4), // cyan-500
  Color(0xFFA855F7), // purple-500
];

Color _processColor(String? name) {
  if (name == null || name.isEmpty) return AppColors.textMuted;
  // Simple deterministic hash — fold codeUnits into an int.
  final h = name.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
  return _processPalette[h % _processPalette.length];
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
              'Chưa có dây chuyền nào hoạt động',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when filters yield zero matches but `workcenters` itself isn't
/// empty — distinguishes "nothing matches your search" from "no data".
class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Không tìm thấy dây chuyền nào khớp.',
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Thử đổi từ khoá hoặc bỏ chọn process.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Bỏ tất cả bộ lọc'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
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
    );
  }
}
