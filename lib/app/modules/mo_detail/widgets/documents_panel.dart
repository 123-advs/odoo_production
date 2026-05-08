import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/attachment_model.dart';
import '../mo_detail_controller.dart';

class DocumentsPanel extends GetView<MoDetailController> {
  const DocumentsPanel({super.key});

  static bool get _supportsCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mutating = controller.isMutating.value;
      final mo = controller.mo.value;

      final canUpload = mo != null && mo.isInProgress;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canUpload) ...[
            Row(
              children: [
                if (_supportsCamera) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          mutating ? null : controller.uploadFromCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Chụp ảnh'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: mutating ? null : controller.uploadFromFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Chọn tệp'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: controller.attachments.isEmpty
                ? const _EmptyState()
                : Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: controller.attachments.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) =>
                          _AttachmentRow(attachment: controller.attachments[i]),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment});

  final AttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MoDetailController>();
    final dateText = attachment.uploadDate == null
        ? '—'
        : DateFormat('dd/MM/yyyy HH:mm').format(attachment.uploadDate!);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Icon(_iconFor(attachment.fileName),
              size: 28, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$dateText · ${attachment.uploadByName ?? '—'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (attachment.remark != null)
                  Text(
                    attachment.remark!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tải xuống',
            onPressed: () => c.openAttachment(attachment),
            icon: const Icon(Icons.download_outlined),
          ),
          Obx(() => IconButton(
                tooltip: 'Xoá',
                onPressed: c.isMutating.value
                    ? null
                    : () => c.deleteAttachment(attachment),
                icon: const Icon(Icons.delete_outline),
              )),
        ],
      ),
    );
  }

  static IconData _iconFor(String fileName) {
    final ext = fileName.toLowerCase().split('.').lastOrNull ?? '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
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
            Icon(Icons.attach_file_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có tài liệu nào.\n'
              'Bấm "Chụp ảnh" hoặc "Chọn tệp" để bắt đầu.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
