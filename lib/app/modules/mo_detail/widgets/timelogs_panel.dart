import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/timelog_model.dart';
import '../mo_detail_controller.dart';

class TimelogsPanel extends GetView<MoDetailController> {
  const TimelogsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = controller.timelogs;
      if (logs.isEmpty) return const _EmptyState();
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return _TimelogsTable(logs: logs);
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _TimelogCard(log: logs[i]),
          );
        },
      );
    });
  }
}

class _TimelogsTable extends StatelessWidget {
  const _TimelogsTable({required this.logs});

  final List<TimelogModel> logs;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 64,
            ),
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              dividerThickness: 1,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columnSpacing: AppSpacing.lg,
              columns: const [
                DataColumn(label: Text('Loại')),
                DataColumn(label: Text('Chuyền')),
                DataColumn(label: Text('Công nhân')),
                DataColumn(label: Text('Ngày bắt đầu')),
                DataColumn(label: Text('Ngày kết thúc')),
                DataColumn(label: Text('Sự cố')),
                DataColumn(label: Text('Ngày phát sinh')),
              ],
              rows: [
                for (final l in logs)
                  DataRow(
                    cells: [
                      DataCell(_TypeChip(log: l)),
                      DataCell(Text(l.workcenterName ?? '—')),
                      DataCell(Text(l.workerName ?? '—')),
                      DataCell(Text(_dt(l.startDate))),
                      DataCell(Text(_dt(l.endDate))),
                      DataCell(Text(l.issue ?? '—')),
                      DataCell(Text(_dt(l.issueDate))),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dt(DateTime? v) => v == null ? '—' : _fmt.format(v);
}

class _TimelogCard extends StatelessWidget {
  const _TimelogCard({required this.log});

  final TimelogModel log;

  static final _fmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeChip(log: log),
                const Spacer(),
                Text(
                  log.timestamp == null
                      ? '—'
                      : _fmt.format(log.timestamp!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              log.issue ?? '—',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 4,
              children: [
                if (log.workcenterName != null)
                  _Meta(
                    icon: Icons.precision_manufacturing_outlined,
                    text: log.workcenterName!,
                  ),
                if (log.workerName != null)
                  _Meta(
                    icon: Icons.person_outline,
                    text: log.workerName!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.log});

  final TimelogModel log;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = log.isStart
        ? (AppColors.success, Icons.play_arrow_rounded, 'Bắt đầu')
        : log.isEnd
            ? (AppColors.warning, Icons.pause_rounded, 'Tạm dừng')
            : (AppColors.textMuted, Icons.circle_outlined, 'Khác');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
            Icon(Icons.history_toggle_off_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có sự kiện dừng máy nào.\n'
              'Khi bấm Bắt đầu / Tạm dừng ở tab "Công đoạn", lịch sử sẽ '
              'xuất hiện tại đây.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
