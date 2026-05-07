import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../data/models/workcenter_model.dart';
import '../../data/providers/odoo_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
// import '../../widgets/app_notify.dart';

class WorkcenterPickerController extends GetxController {
  final isLoading = false.obs;
  final workcenters = <WorkcenterModel>[].obs;
  final errorMessage = RxnString();

  /// Free-text filter applied to name + code + process name.
  final searchQuery = ''.obs;

  /// When non-null, restrict cards to a single process. `null` = all.
  final selectedProcess = RxnString();

  final _provider = OdooProvider();
  StorageService get _storage => Get.find<StorageService>();

  String get userName => _storage.userName ?? '';

  /// Distinct, sorted list of process names found in the loaded workcenters.
  /// Used to render the filter chips.
  List<String> get uniqueProcesses {
    final set = <String>{};
    for (final w in workcenters) {
      final p = w.processName;
      if (p != null && p.isNotEmpty) set.add(p);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Returns workcenters that match the current search query AND selected
  /// process. Touches all three observables so callers wrapped in Obx
  /// rebuild on any of them changing.
  List<WorkcenterModel> get filteredWorkcenters {
    final q = searchQuery.value.trim().toLowerCase();
    final p = selectedProcess.value;
    return workcenters.where((w) {
      if (p != null && w.processName != p) return false;
      if (q.isEmpty) return true;
      if (w.name.toLowerCase().contains(q)) return true;
      if (w.code != null && w.code!.toLowerCase().contains(q)) return true;
      if (w.processName != null && w.processName!.toLowerCase().contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }

  void setSearchQuery(String v) => searchQuery.value = v;
  void clearSearch() => searchQuery.value = '';

  void toggleProcess(String? name) {
    selectedProcess.value = (selectedProcess.value == name) ? null : name;
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedProcess.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    loadWorkcenters();
  }

  Future<void> loadWorkcenters() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      workcenters.value = await _provider.fetchWorkcenters();
    } on DioException catch (e) {
      errorMessage.value = e.message ?? 'Không tải được danh sách dây chuyền';
    } catch (_) {
      errorMessage.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> select(WorkcenterModel wc) async {
    await _storage.setWorkcenter(
      wc.id,
      wc.name,
      process: wc.processName,
      processId: wc.processId,
    );
    Get.offAllNamed(AppRoutes.moList);
    // AppNotify.success('Đã chọn dây chuyền', wc.name);
  }

  Future<void> logout() async {
    await _provider.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
