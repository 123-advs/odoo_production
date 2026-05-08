import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../data/models/mo_model.dart';
import '../../data/providers/odoo_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_notify.dart';

class MoListController extends GetxController {
  final isLoading = false.obs;
  final mos = <MoModel>[].obs;
  final filter = MoStateFilter.all.obs;
  final selectedId = RxnInt();
  final errorMessage = RxnString();

  final searchQuery = ''.obs;

  final _provider = OdooProvider();
  StorageService get _storage => Get.find<StorageService>();

  int? get workcenterId => _storage.workcenterId;
  int? get workcenterProcessId => _storage.workcenterProcessId;
  String get workcenterName => _storage.workcenterName ?? '';
  String? get workcenterProcess => _storage.workcenterProcess;
  String get userName => _storage.userName ?? '';

  String get headerTitle {
    final name = workcenterName;
    final proc = workcenterProcess;
    if (name.isEmpty) return 'Danh sách MO';
    if (proc == null || proc.isEmpty) return 'Dây chuyền: $name';
    return 'Dây chuyền: $proc — $name';
  }

  MoModel? get selectedMo {
    final id = selectedId.value;
    if (id == null) return null;
    for (final m in mos) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<MoModel> get filteredMos {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return mos.toList();
    return mos.where((m) {
      if (m.name.toLowerCase().contains(q)) return true;
      final pn = m.productName?.toLowerCase();
      if (pn != null && pn.contains(q)) return true;
      final pc = m.productCode?.toLowerCase();
      if (pc != null && pc.contains(q)) return true;
      return false;
    }).toList();
  }

  void setSearchQuery(String v) => searchQuery.value = v;
  void clearSearch() => searchQuery.value = '';

  @override
  void onInit() {
    super.onInit();
    _ensureWorkcenter();
  }

  void _ensureWorkcenter() {
    if (workcenterId == null) {
      Future.microtask(() => Get.offAllNamed(AppRoutes.workcenterPicker));
      return;
    }
    loadMos();
  }

  void setFilter(MoStateFilter f) {
    if (filter.value == f) return;
    filter.value = f;
    selectedId.value = null;
    loadMos();
  }

  void selectMo(int id) => selectedId.value = id;

  Future<void> loadMos() async {
    final wcId = workcenterId;
    if (wcId == null) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      mos.value = await _provider.fetchMoList(
        workcenterId: wcId,
        processId: workcenterProcessId,
        filter: filter.value,
      );

      if (selectedId.value != null &&
          !mos.any((m) => m.id == selectedId.value)) {
        selectedId.value = null;
      }
    } on DioException catch (e) {
      errorMessage.value = e.message ?? 'Không tải được danh sách MO';
    } catch (_) {
      errorMessage.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeWorkcenter() async {
    await _storage.clearWorkcenter();
    Get.offAllNamed(AppRoutes.workcenterPicker);
  }

  Future<void> logout() async {
    await _provider.logout();
    Get.offAllNamed(AppRoutes.login);
    AppNotify.info('Đã đăng xuất', 'Hẹn gặp lại ca sau.');
  }
}
