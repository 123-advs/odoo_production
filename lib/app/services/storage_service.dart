import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  final GetStorage _box = GetStorage();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _kSessionId = 'odoo_session_id';
  static const _kUserId = 'odoo_user_id';
  static const _kUserName = 'odoo_user_name';
  static const _kEmployeeId = 'odoo_employee_id';
  static const _kWorkcenterId = 'workcenter_id';
  static const _kWorkcenterName = 'workcenter_name';
  static const _kWorkcenterProcess = 'workcenter_process';
  static const _kWorkcenterProcessId = 'workcenter_process_id';

  int? get userId => _box.read<int>(_kUserId);
  Future<void> setUserId(int id) => _box.write(_kUserId, id);

  String? get userName => _box.read<String>(_kUserName);
  Future<void> setUserName(String name) => _box.write(_kUserName, name);

  int? get employeeId => _box.read<int>(_kEmployeeId);
  Future<void> setEmployeeId(int? id) =>
      id == null ? _box.remove(_kEmployeeId) : _box.write(_kEmployeeId, id);

  int? get workcenterId => _box.read<int>(_kWorkcenterId);
  String? get workcenterName => _box.read<String>(_kWorkcenterName);
  String? get workcenterProcess => _box.read<String>(_kWorkcenterProcess);
  int? get workcenterProcessId => _box.read<int>(_kWorkcenterProcessId);
  Future<void> setWorkcenter(
    int id,
    String name, {
    String? process,
    int? processId,
  }) async {
    await _box.write(_kWorkcenterId, id);
    await _box.write(_kWorkcenterName, name);
    if (process != null && process.isNotEmpty) {
      await _box.write(_kWorkcenterProcess, process);
    } else {
      await _box.remove(_kWorkcenterProcess);
    }
    if (processId != null) {
      await _box.write(_kWorkcenterProcessId, processId);
    } else {
      await _box.remove(_kWorkcenterProcessId);
    }
  }

  Future<void> clearWorkcenter() async {
    await _box.remove(_kWorkcenterId);
    await _box.remove(_kWorkcenterName);
    await _box.remove(_kWorkcenterProcess);
    await _box.remove(_kWorkcenterProcessId);
  }

  Future<String?> readSessionId() => _secure.read(key: _kSessionId);
  Future<void> writeSessionId(String value) =>
      _secure.write(key: _kSessionId, value: value);

  Future<void> clearSession() async {
    await _secure.delete(key: _kSessionId);
    await _box.remove(_kUserId);
    await _box.remove(_kUserName);
    await _box.remove(_kEmployeeId);
    await clearWorkcenter();
  }
}
