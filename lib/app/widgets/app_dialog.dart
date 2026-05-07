import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';

class AppDialog {
  AppDialog._();

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Đồng ý',
    String cancelLabel = 'Hủy',
    DialogType type = DialogType.warning,
    Color? confirmColor,
  }) async {
    final ctx = Get.context;
    if (ctx == null) return false;

    var result = false;
    await AwesomeDialog(
      context: ctx,
      dialogType: type,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      dismissOnTouchOutside: true,
      dialogBackgroundColor: AppColors.surface,
      title: title,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      desc: message,
      descTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textMuted,
        height: 1.5,
      ),
      btnCancelText: cancelLabel,
      btnOkText: confirmLabel,
      btnCancelColor: AppColors.textMuted,
      btnOkColor: confirmColor ?? AppColors.primary,
      buttonsTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      btnCancelOnPress: () => result = false,
      btnOkOnPress: () => result = true,
    ).show();
    return result;
  }

  static Future<void> info({
    required String title,
    required String message,
    String okLabel = 'Đã hiểu',
  }) async {
    final ctx = Get.context;
    if (ctx == null) return;
    await AwesomeDialog(
      context: ctx,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      dialogBackgroundColor: AppColors.surface,
      title: title,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      desc: message,
      descTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textMuted,
        height: 1.5,
      ),
      btnOkText: okLabel,
      btnOkColor: AppColors.accent,
      btnOkOnPress: () {},
    ).show();
  }
}
