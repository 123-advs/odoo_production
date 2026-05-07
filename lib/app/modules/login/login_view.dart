import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const Center(
                      child: Icon(
                        Icons.factory_outlined,
                        size: 88,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Center(
                      child: Text(
                        'TCS MMS Worker',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Center(
                      child: Text(
                        'Đăng nhập để bắt đầu ca làm',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Obx(() => AppTextField(
                          label: 'Tên đăng nhập',
                          controller: controller.loginCtrl,
                          hintText: 'tên đăng nhập Odoo',
                          prefixIcon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          errorText: controller.loginError.value,
                          onChanged: controller.onLoginChanged,
                        )),
                    const SizedBox(height: AppSpacing.lg),
                    Obx(() => AppTextField(
                          label: 'Mật khẩu',
                          controller: controller.passwordCtrl,
                          hintText: 'Nhập mật khẩu',
                          prefixIcon: Icons.lock_outline,
                          obscureText: controller.obscurePassword.value,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          errorText: controller.passwordError.value,
                          onChanged: controller.onPasswordChanged,
                          onSubmitted: (_) => controller.submit(),
                          suffix: IconButton(
                            onPressed: controller.toggleObscure,
                            icon: Icon(
                              controller.obscurePassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                    Obx(() {
                      final err = controller.formError.value;
                      if (err == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusButton),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                err,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.sm),
                    Obx(() => PrimaryButton(
                          label: 'ĐĂNG NHẬP',
                          isLoading: controller.isLoading.value,
                          onPressed: controller.submit,
                        )),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: AppSpacing.md),
                    const Center(
                      child: Text(
                        '© 2026 TCS TECH — Manufacturing Module',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
