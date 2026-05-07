import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../data/providers/odoo_provider.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  final loginCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final loginError = RxnString();
  final passwordError = RxnString();
  final formError = RxnString();

  final _provider = OdooProvider();

  void toggleObscure() => obscurePassword.toggle();

  void onLoginChanged(String _) {
    if (loginError.value != null) loginError.value = null;
    if (formError.value != null) formError.value = null;
  }

  void onPasswordChanged(String _) {
    if (passwordError.value != null) passwordError.value = null;
    if (formError.value != null) formError.value = null;
  }

  bool _validate() {
    var ok = true;
    if (loginCtrl.text.trim().isEmpty) {
      loginError.value = 'Vui lòng nhập tên đăng nhập';
      ok = false;
    }
    if (passwordCtrl.text.isEmpty) {
      passwordError.value = 'Vui lòng nhập mật khẩu';
      ok = false;
    }
    return ok;
  }

  Future<void> submit() async {
    if (isLoading.value) return;
    if (!_validate()) return;

    isLoading.value = true;
    formError.value = null;
    try {
      final uid = await _provider.login(
        login: loginCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      if (uid == null) {
        formError.value = 'Tài khoản hoặc mật khẩu không đúng';
        return;
      }
      Get.offAllNamed(AppRoutes.workcenterPicker);
    } on DioException catch (e) {
      formError.value = e.message ?? 'Không kết nối được máy chủ';
    } catch (_) {
      formError.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
