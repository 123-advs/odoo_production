import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/workorder_model.dart';
import '../mo_detail_controller.dart';

class WorkorderPanel extends GetView<MoDetailController> {
  const WorkorderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.workorders.length;
      final wos = controller.filteredWorkorders;
      if (wos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.engineering_outlined,
                    size: 48, color: AppColors.textMuted),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Chưa có công đoạn nào.\n'
                  'Công đoạn sinh tự động khi xác nhận vật tư đầu tiên.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: wos.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _WorkorderCard(wo: wos[i]),
      );
    });
  }
}

class _WorkorderCard extends StatelessWidget {
  const _WorkorderCard({required this.wo});

  final WorkorderModel wo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    wo.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StateChip(state: wo.state),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                if (wo.workcenterName != null)
                  _Meta(
                    icon: Icons.precision_manufacturing_outlined,
                    text: wo.workcenterName!,
                  ),
                _Meta(
                  icon: Icons.groups_outlined,
                  text: '${wo.workerIds.length} công nhân',
                ),
                if (wo.isProgress)
                  _LiveDuration(startedAt: wo.dateStart, baseMinutes: wo.duration)
                else if (wo.duration > 0)
                  _Meta(
                    icon: Icons.timer_outlined,
                    text: _fmtDuration(wo.duration),
                  ),
                if (wo.durationExpected > 0)
                  _Meta(
                    icon: Icons.schedule_outlined,
                    text: 'Dự kiến ${_fmtDuration(wo.durationExpected)}',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionRow(wo: wo),
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(double minutes) {
    if (minutes < 60) return '${minutes.toStringAsFixed(0)} phút';
    final h = (minutes / 60).floor();
    final m = (minutes - h * 60).round();
    return m == 0 ? '$h giờ' : '${h}h ${m}p';
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.wo});

  final WorkorderModel wo;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoDetailController>();
    return Obx(() {
      final mutating = c.isMutating.value;
      if (wo.isTerminal) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            wo.isDone ? 'Đã hoàn tất' : 'Đã hủy',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        );
      }
      return Row(
        children: [
          if (wo.canStart)
            Expanded(
              child: FilledButton.icon(
                onPressed: mutating ? null : () => c.startWorkorder(wo),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          if (wo.canPause) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: mutating ? null : () => c.pauseWorkorder(wo),
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Tạm dừng'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          if (wo.canFinish)
            Expanded(
              child: FilledButton.icon(
                onPressed: mutating ? null : () => c.finishWorkorder(wo),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Hoàn tất'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      'progress' => (AppColors.warning, 'Đang chạy'),
      'done' => (AppColors.success, 'Hoàn tất'),
      'cancel' => (AppColors.error, 'Đã hủy'),
      'ready' => (AppColors.accent, 'Sẵn sàng'),
      'pending' => (AppColors.textMuted, 'Chờ'),
      'waiting' => (AppColors.textMuted, 'Chờ vật tư'),
      _ => (AppColors.textMuted, state),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LiveDuration extends StatefulWidget {
  const _LiveDuration({required this.startedAt, required this.baseMinutes});

  final DateTime? startedAt;
  final double baseMinutes;

  @override
  State<_LiveDuration> createState() => _LiveDurationState();
}

class _LiveDurationState extends State<_LiveDuration> {
  Timer? _timer;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_anchor).inSeconds;
    final totalSeconds = (widget.baseMinutes * 60).round() + elapsed;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final txt = h > 0
        ? '${_pad(h)}:${_pad(m)}:${_pad(s)}'
        : '${_pad(m)}:${_pad(s)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, size: 16, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xs),
        Text(
          txt,
          style: const TextStyle(
            fontSize: 13,
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  static String _pad(int v) => v < 10 ? '0$v' : '$v';
}
