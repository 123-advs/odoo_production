import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';

class SplashController extends GetxController {
  Timer? _decideTimer;
  bool _disposed = false;

  @override
  void onReady() {
    super.onReady();
    _decideTimer = Timer(const Duration(milliseconds: 400), _decide);
  }

  Future<void> _decide() async {
    if (_disposed) return;
    try {
      final updating = await Get.find<UpdateService>().checkAndPrompt();
      if (updating || _disposed) return;

      final storage = Get.find<StorageService>();
      String? session;
      try {
        session = await storage.readSessionId().timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );
      } catch (e, st) {
        debugPrint('[Splash] readSessionId failed: $e');
        debugPrintStack(stackTrace: st);
        session = null;
      }

      if (_disposed) return;
      if (session != null && session.isNotEmpty) {
        Get.offAllNamed(
          storage.workcenterId == null
              ? AppRoutes.workcenterPicker
              : AppRoutes.moList,
        );
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e, st) {
      debugPrint('[Splash] uncaught: $e');
      debugPrintStack(stackTrace: st);
      if (!_disposed) Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _decideTimer?.cancel();
    super.onClose();
  }
}
