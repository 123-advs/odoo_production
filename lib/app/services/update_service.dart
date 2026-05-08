import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/app_dialog.dart';
import 'api_service.dart';

class UpdateInfo {
  final String version;
  final String url;
  final bool mandatory;
  final String notes;
  final String sha256;

  UpdateInfo({
    required this.version,
    required this.url,
    required this.mandatory,
    required this.notes,
    required this.sha256,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        version: (j['version'] ?? '0.0.0').toString(),
        url: (j['url'] ?? '').toString(),
        mandatory: j['mandatory'] == true,
        notes: (j['notes'] ?? '').toString(),
        sha256: (j['sha256'] ?? '').toString(),
      );
}

class UpdateService extends GetxService {
  static const _endpoint = '/tcs_production/latest_version';

  Future<UpdateInfo?> _fetchLatest() async {
    try {
      final dio = Get.find<ApiService>().dio;
      final res = await dio.get(_endpoint);
      if (res.statusCode != 200 || res.data is! Map) return null;
      return UpdateInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      debugPrint('[UpdateService] fetch failed: $e');
      return null;
    }
  }

  Future<bool> checkAndPrompt() async {
    if (!Platform.isWindows) return false;

    final info = await _fetchLatest();
    if (info == null || info.url.isEmpty) return false;

    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;
    if (!_isNewer(info.version, current)) return false;

    final accepted = info.mandatory ||
        await AppDialog.confirm(
          title: 'Có bản cập nhật mới',
          message:
              'Phiên bản $current → ${info.version}\n\n${info.notes.isNotEmpty ? info.notes : "Tải và cài đặt phiên bản mới ngay?"}',
          confirmLabel: 'Cập nhật',
          cancelLabel: 'Để sau',
        );
    if (!accepted) return false;

    return _downloadAndRun(info);
  }

  Future<bool> _downloadAndRun(UpdateInfo info) async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final installerPath =
          '${tmpDir.path}\\TCSProduction-Setup-${info.version}.exe';

      await Dio().download(
        info.url,
        installerPath,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      await Process.start(
        installerPath,
        const [
          '/SILENT',
          '/CLOSEAPPLICATIONS',
          '/RESTARTAPPLICATIONS',
          '/NORESTART',
        ],
        mode: ProcessStartMode.detached,
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));
      exit(0);
    } catch (e) {
      debugPrint('[UpdateService] install failed: $e');
      return false;
    }
  }

  bool _isNewer(String remote, String local) {
    final r = _parse(remote);
    final l = _parse(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  List<int> _parse(String v) {
    final parts = v.split(RegExp(r'[.+-]'));
    final out = <int>[0, 0, 0];
    for (var i = 0; i < 3 && i < parts.length; i++) {
      out[i] = int.tryParse(parts[i]) ?? 0;
    }
    return out;
  }
}
