import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../data/models/actual_wizard_model.dart';
import '../../data/models/attachment_model.dart';
import '../../data/models/bom_info_model.dart';
import '../../data/models/issue_model.dart';
import '../../data/models/mo_detail_model.dart';
import '../../data/models/mo_item_model.dart';
import '../../data/models/production_model.dart';
import '../../data/models/timelog_model.dart';
import '../../data/models/workorder_model.dart';
import '../../data/providers/odoo_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_notify.dart';
import 'widgets/actual_wizard_modal.dart';
import 'widgets/oee_issue_modal.dart';
import 'widgets/qc_form_modal.dart';
import 'widgets/qc_history_modal.dart';
import 'widgets/received_qty_modal.dart';
import 'widgets/return_wizard_modal.dart';

class MoDetailController extends GetxController {
  MoDetailController({required this.moId});

  final int moId;

  final isLoading = false.obs;
  final isMutating = false.obs;
  final mo = Rxn<MoDetailModel>();
  final workorders = <WorkorderModel>[].obs;
  final productions = <ProductionModel>[].obs;
  final attachments = <AttachmentModel>[].obs;
  final timelogs = <TimelogModel>[].obs;
  final errorMessage = RxnString();

  final selectedItemIds = <int>{}.obs;

  final _provider = OdooProvider();
  StorageService get _storage => Get.find<StorageService>();

  int? get workcenterId => _storage.workcenterId;
  String? get workcenterName => _storage.workcenterName;

  int? get _employeeId => _storage.employeeId;

  List<MoItemModel> get filteredItems {
    final all = mo.value?.items ?? const <MoItemModel>[];
    final wcId = workcenterId;
    final empId = _employeeId;
    return all.where((i) {
      if (wcId != null && i.workcenterId != wcId) return false;
      if (empId != null && i.workerId != null && i.workerId != empId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<WorkorderModel> get filteredWorkorders {
    final wcId = workcenterId;
    final empId = _employeeId;
    return workorders.where((w) {
      if (wcId != null && w.workcenterId != wcId) return false;
      if (empId != null && w.workerIds.isNotEmpty &&
          !w.workerIds.contains(empId)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  Future<void> loadDetail() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _provider.fetchMoDetail(moId),
        _provider.fetchWorkorders(moId),
        _provider.fetchProductions(moId),
        _provider.fetchAttachments(moId),
        _provider.fetchTimelogs(moId),
      ]);
      final detail = results[0] as MoDetailModel;
      final wos = results[1] as List<WorkorderModel>;
      final prods = results[2] as List<ProductionModel>;
      final atts = results[3] as List<AttachmentModel>;
      final tls = results[4] as List<TimelogModel>;
      mo.value = detail;
      workorders.value = wos;
      productions.value = prods;
      attachments.value = atts;
      timelogs.value = tls;
      _pruneSelection(detail);
    } on DioException catch (e) {
      errorMessage.value = e.message ?? 'Không tải được chi tiết MO';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _pruneSelection(MoDetailModel detail) {
    final wcId = workcenterId;
    final empId = _employeeId;
    final scoped = detail.items.where((i) {
      if (wcId != null && i.workcenterId != wcId) return false;
      if (empId != null && i.workerId != null && i.workerId != empId) {
        return false;
      }
      return true;
    });
    final draftIds = scoped.where((i) => i.isDraft).map((i) => i.id).toSet();
    selectedItemIds.removeWhere((id) => !draftIds.contains(id));
  }

  void toggleItem(int id) {
    if (selectedItemIds.contains(id)) {
      selectedItemIds.remove(id);
    } else {
      selectedItemIds.add(id);
    }
  }

  void selectAllDraftItems() {
    selectedItemIds.assignAll(
      filteredItems.where((i) => i.isDraft).map((i) => i.id),
    );
  }

  void clearSelection() => selectedItemIds.clear();

  Future<void> scanLot(String lotName) async {
    final wc = workcenterId;
    if (wc == null) {
      AppNotify.error('Thiếu dây chuyền',
          'Vui lòng chọn dây chuyền trước khi quét.');
      return;
    }
    if (isMutating.value) return;
    isMutating.value = true;
    try {
      await _provider.scanItemLot(
        moId: moId,
        lotName: lotName,
        workcenterId: wc,
      );
      AppNotify.success('Đã quét lot', lotName);
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Quét lot thất bại',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Quét lot thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> confirmMo() async {
    if (isMutating.value) return;
    final ok = await AppDialog.confirm(
      title: 'Bắt đầu MO',
      message: 'Xác nhận bắt đầu thực hiện MO này?',
      confirmLabel: 'Bắt đầu',
    );
    if (!ok) return;
    isMutating.value = true;
    try {
      await _provider.confirmMo(moId);
      AppNotify.success('Đã bắt đầu MO', mo.value?.name ?? '');
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không bắt đầu được MO',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không bắt đầu được MO', e.toString());
    } finally {
      isMutating.value = false;
    }
  }
.
  Future<void> completeMo() async {
    if (isMutating.value) return;
    final cur = mo.value;
    if (cur == null) return;
    if (!cur.isInProgress) {
      AppNotify.warning('Không thể hoàn tất',
          'MO không ở trạng thái Đang chạy.');
      return;
    }

    const tolerance = 0.000001;
    final blockers = <String>[];
    final unfinishedWos = workorders
        .where((w) => w.state != 'done' && w.state != 'cancel')
        .toList();
    if (unfinishedWos.isNotEmpty) {
      blockers.add(
          '${unfinishedWos.length} công đoạn chưa hoàn tất (đến tab Công đoạn để hoàn tất)');
    }
    final unfinishedProds =
        productions.where((p) => p.state != 'done').toList();
    if (unfinishedProds.isNotEmpty) {
      blockers.add(
          '${unfinishedProds.length} lần sản lượng chưa hoàn tất (chưa PQC/OQC)');
    }
    final unconfirmedItems =
        cur.items.where((i) => i.state != 'confirm').toList();
    if (unconfirmedItems.isNotEmpty) {
      blockers.add(
          '${unconfirmedItems.length} vật tư chưa xác nhận (tab Vật tư → Xác nhận)');
    }
    final remainingItems =
        cur.items.where((i) => i.remainQty > tolerance).toList();
    if (remainingItems.isNotEmpty) {
      blockers.add(
          '${remainingItems.length} vật tư còn dư chưa tiêu thụ hoặc trả (Trả vật tư)');
    }

    if (blockers.isNotEmpty) {
      await AppDialog.info(
        title: 'Chưa hoàn tất được MO',
        message:
            'Cần xử lý các điều kiện sau trước khi hoàn tất:\n\n• ${blockers.join("\n• ")}',
      );
      return;
    }

    final ok = await AppDialog.confirm(
      title: 'Hoàn tất MO',
      message:
          'Hoàn tất "${cur.name}"? Hành động này khoá MO ở trạng thái Done '
          'và không thể hoàn tác từ app.',
      confirmLabel: 'Hoàn tất MO',
    );
    if (!ok) return;

    isMutating.value = true;
    try {
      await _provider.completeMo(moId);
      AppNotify.success('Đã hoàn tất MO', cur.name);
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không hoàn tất được MO',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không hoàn tất được MO', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> confirmSelectedItems() async {
    if (isMutating.value) return;
    final ids = selectedItemIds.toList();
    if (ids.isEmpty) {
      AppNotify.warning(
          'Chưa chọn vật tư', 'Tích chọn ít nhất một dòng vật tư draft.');
      return;
    }
    isMutating.value = true;
    try {
      await _provider.confirmItems(moId: moId, itemIds: ids);
      AppNotify.success(
          'Đã xác nhận vật tư', 'Đã xác nhận ${ids.length} dòng.');
      selectedItemIds.clear();
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Xác nhận thất bại',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Xác nhận thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> _runOeeFlow(WorkorderModel wo, OeeMode mode) async {
    if (isMutating.value) return;
    isMutating.value = true;
    final operatingStatus = mode == OeeMode.start ? 'on' : 'off';
    List<IssueModel> issues;
    try {
      issues = await _provider.fetchIssues(operatingStatus);
    } on DioException catch (e) {
      isMutating.value = false;
      AppNotify.error('Không tải được lý do',
          e.message ?? 'Không gọi được máy chủ.');
      return;
    } finally {
      isMutating.value = false;
    }

    final picked = await Get.dialog<IssueModel>(
      OeeIssueModal(
        workorderName: wo.name,
        issues: issues,
        mode: mode,
      ),
      barrierDismissible: false,
    );
    if (picked == null) return;

    isMutating.value = true;
    final actionLabel = mode == OeeMode.start ? 'bắt đầu' : 'tạm dừng';
    try {
      await _provider.submitOeeWizard(
        workorderId: wo.id,
        employeeId: _storage.employeeId,
        issueId: picked.id,
      );
      AppNotify.success(
          mode == OeeMode.start ? 'Đã bắt đầu' : 'Đã tạm dừng',
          '${wo.name} — ${picked.name}');
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không $actionLabel được công đoạn',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không $actionLabel được công đoạn', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> startWorkorder(WorkorderModel wo) =>
      _runOeeFlow(wo, OeeMode.start);

  Future<void> pauseWorkorder(WorkorderModel wo) =>
      _runOeeFlow(wo, OeeMode.pause);

  Future<void> finishWorkorder(WorkorderModel wo) async {
    if (isMutating.value) return;

    const tolerance = 0.000001;
    final blockers = filteredItems
        .where((i) => i.remainQty > tolerance)
        .toList();
    if (blockers.isNotEmpty) {
      final lines = blockers
          .take(8)
          .map((i) =>
              '· ${i.productName} (${i.lotName}): còn ${_fmtQty(i.remainQty)} ${i.uom}')
          .join('\n');
      final more =
          blockers.length > 8 ? '\n… và ${blockers.length - 8} dòng khác' : '';
      await AppDialog.info(
        title: 'Chưa thể hoàn tất',
        message:
            'Vật tư đã nhận chưa được tiêu thụ hết. Hãy nhập sản lượng '
            'hoặc trả vật tư thừa trước khi hoàn tất:\n\n$lines$more',
      );
      return;
    }

    isMutating.value = true;
    try {
      await _provider.finishWorkorder(wo.id);
      AppNotify.success('Đã hoàn tất công đoạn', wo.name);
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không hoàn tất được',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không hoàn tất được', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  static String _fmtQty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  // Actual qty wizard

  Future<void> openActualWizard() async {
    if (isMutating.value) return;
    final wc = workcenterId;
    final cur = mo.value;
    if (wc == null || cur == null) return;
    isMutating.value = true;
    int? wizardId;
    try {
      const tolerance = 0.000001;
      final empId = _employeeId;
      final eligibleItems = cur.items.where((i) {
        if (i.workcenterId != wc) return false;
        if (empId != null && i.workerId != null && i.workerId != empId) {
          return false;
        }
        if (i.state != 'confirm') return false;
        if (i.remainQty <= tolerance) return false;
        return true;
      }).toList();

      if (eligibleItems.isEmpty) {
        isMutating.value = false;
        AppNotify.warning(
          'Chưa có vật tư',
          'Không tìm thấy vật tư đã xác nhận còn dư cho dây chuyền + công nhân hiện tại.',
        );
        return;
      }

      final linePayloads = eligibleItems.map((i) => <String, dynamic>{
            'product_id': i.productId,
            'product_name': i.productName,
            'lot_id': i.lotId ?? false,
            'received_qty': i.receivedQty,
            'remain_qty': i.remainQty,
            'uom_id': i.uomId ?? false,
            'item_id': i.id,
          }).toList();

      // remain = target - Σ(operations.actual_qty for this workcenter)
      final totalActual = productions
          .where((p) => p.workcenterId == wc)
          .fold<double>(0, (s, p) => s + p.actualQty);
      final wizardRemain = cur.targetQty - totalActual;

      // 2) Create wizard + fetch BOM in parallel
      final wizardIdFut = _provider.createActualWizard(
        moId: moId,
        workcenterId: wc,
        workerId: empId,
        productSemiId: cur.productSemiId,
        targetQty: cur.targetQty,
        remainQty: wizardRemain,
        linePayloads: linePayloads,
      );
      final bomFut = cur.bomId != null
          ? _provider.fetchBomInfo(cur.bomId!)
          : Future<BomInfoModel?>.value(null);
      wizardId = await wizardIdFut;
      // 3) Read wizard fields + lines
      final wizardFut = _provider.readActualWizard(wizardId);
      final results = await Future.wait([wizardFut, bomFut]);
      final wizard = results[0] as ActualWizardModel;
      final bom = results[1] as BomInfoModel?;
      isMutating.value = false;

      if (wizard.lines.isEmpty) {
        AppNotify.warning(
          'Chưa có vật tư',
          'Wizard không có dòng nào — vật tư có thể đã thay đổi, hãy thử lại.',
        );
        return;
      }

      // 3) Show modal
      final result = await Get.dialog<ActualWizardResult>(
        ActualWizardModal(wizard: wizard, bom: bom),
        barrierDismissible: false,
      );
      if (result == null) return;

      // 4) Confirm — write line_ids + actual_qty + action_confirm
      isMutating.value = true;
      await _provider.confirmActualWizard(
        wizardId: wizardId,
        actualQty: result.actualQty,
        usingQtyByLineId: result.usingQtyByLineId,
        otherLossByLineId: result.otherLossByLineId,
      );
      AppNotify.success('Đã ghi sản lượng',
          'Sản lượng ${result.actualQty} đã được lưu.');
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không lưu được sản lượng',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không lưu được sản lượng', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  // PQC / OQC

  Future<void> openQc(ProductionModel production) async {
    if (isMutating.value) return;
    final isOqc = production.isLastLevel;
    isMutating.value = true;
    try {
      // 1) Fetch QC form preview (title + check_list + production info).
      final form = await _provider.previewQcForm(
        productionId: production.id,
        isOqc: isOqc,
      );
      isMutating.value = false;

      // 2) Show modal — worker fills check_list + OK/NG.
      final result = await Get.dialog<QcFormResult>(
        QcFormModal(production: production, form: form),
        barrierDismissible: false,
      );
      if (result == null) return;

      // 3) Submit. Mirrors the two RPCs the MMS web "Apply" button issues:
      //    a) apply_pqc_result / apply_oqc_result — write totals + persist
      //       pqc_check_list / oqc_check_list JSON on the production.
      //    b) create_history_pqc / create_history_oqc — record an audit
      //       entry in mes.qc_form.history with the full inspectionData.
      isMutating.value = true;
      if (isOqc) {
        await _provider.applyOqc(
          productionId: production.id,
          okQty: result.okQty,
          ngQty: result.ngQty,
          checkList: result.checkListJson,
        );
      } else {
        await _provider.applyPqc(
          productionId: production.id,
          okQty: result.okQty,
          ngQty: result.ngQty,
          checkList: result.checkListJson,
        );
      }
      try {
        await _provider.createQcHistory(
          inspectionData: result.inspectionData,
          isOqc: isOqc,
        );
      } on DioException catch (e) {
        AppNotify.warning(
          'Đã lưu kết quả nhưng không tạo được lịch sử',
          e.message ?? 'Liên hệ admin để kiểm tra.',
        );
      }
      AppNotify.success(
        'Đã ghi ${production.qcKind}',
        'OK ${result.okQty} / NG ${result.ngQty}',
      );
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Không ghi được ${production.qcKind}',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không ghi được ${production.qcKind}', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  // Documents

  static bool get _supportsCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> uploadFromCamera() async {
    if (isMutating.value) return;
    if (!_supportsCamera) {
      AppNotify.warning('Không khả dụng',
          'Chụp ảnh chỉ hỗ trợ trên Android. Hãy dùng "Chọn tệp".');
      return;
    }
    final picker = ImagePicker();
    final XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
    } catch (e) {
      AppNotify.error('Không mở được camera', e.toString());
      return;
    }
    if (image == null) return;
    await _uploadFile(name: image.name, bytes: await image.readAsBytes());
  }

  Future<void> uploadFromFile() async {
    if (isMutating.value) return;
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(withData: true);
    } catch (e) {
      AppNotify.error('Không mở được hộp thoại tệp', e.toString());
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await _readPath(file.path);
    if (bytes == null || bytes.isEmpty) {
      AppNotify.error('Không đọc được tệp', 'Tệp rỗng hoặc không truy cập được.');
      return;
    }
    await _uploadFile(name: file.name, bytes: bytes);
  }

  Future<List<int>?> _readPath(String? path) async {
    if (path == null) return null;
    return File(path).readAsBytes();
  }

  Future<void> _uploadFile({
    required String name,
    required List<int> bytes,
  }) async {
    isMutating.value = true;
    try {
      final encoded = base64Encode(bytes);
      await _provider.uploadAttachment(
        moId: moId,
        fileName: name,
        base64Data: encoded,
      );
      AppNotify.success('Đã tải lên', name);
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Tải lên thất bại',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Tải lên thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> openAttachment(AttachmentModel attachment) async {
    final url = Uri.parse(
        '${ApiConstants.odooBaseUrl}${attachment.downloadPath()}');
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) {
        AppNotify.error('Không mở được tệp', url.toString());
      }
    } catch (e) {
      AppNotify.error('Không mở được tệp', e.toString());
    }
  }

  Future<void> deleteAttachment(AttachmentModel attachment) async {
    if (isMutating.value) return;
    final ok = await AppDialog.confirm(
      title: 'Xoá tài liệu',
      message: 'Xoá "${attachment.fileName}"? Hành động không thể hoàn tác.',
      confirmLabel: 'Xoá',
    );
    if (!ok) return;
    isMutating.value = true;
    try {
      await _provider.deleteAttachment(attachment.id);
      AppNotify.success('Đã xoá', attachment.fileName);
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Xoá thất bại', e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Xoá thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> editItemQty(MoItemModel item) async {
    if (isMutating.value) return;
    if (!item.isDraft) {
      AppNotify.warning('Không thể sửa',
          'Dòng đã xác nhận, không thể đổi số lượng nhận.');
      return;
    }
    final qty = await Get.dialog<double>(
      ReceivedQtyModal(item: item),
      barrierDismissible: false,
    );
    if (qty == null || qty <= 0) return;
    isMutating.value = true;
    try {
      await _provider.setItemReceivedQty(itemId: item.id, qty: qty);
      AppNotify.success(
          'Đã cập nhật', '${item.lotName}: nhận $qty ${item.uom}');
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error('Cập nhật thất bại',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Cập nhật thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  List<MoItemModel> get returnableItems {
    return filteredItems.where((i) {
      if (i.state != 'confirm') return false;
      if (i.remainQty <= 0.000001) return false;
      return true;
    }).toList();
  }

  bool get hasReturnableItems => returnableItems.isNotEmpty;

  Future<void> openReturnWizard() async {
    if (isMutating.value) return;
    if (!hasReturnableItems) {
      AppNotify.info(
        'Không có vật tư còn dư',
        'Tất cả vật tư đã xác nhận đã được tiêu thụ hết.',
      );
      return;
    }
    isMutating.value = true;
    int? wizardId;
    try {
      // 1) Build line payloads from local state — server `_build_and_create`
      //    is private, so go through public `create` with prebuilt rows.
      final eligible = returnableItems;
      final linePayloads = eligible.map((i) => <String, dynamic>{
            'item_id': i.id,
            'product_id': i.productId,
            'product_name': i.productName,
            'lot_id': i.lotId ?? false,
            'remain_qty': i.remainQty,
            'received_qty': i.receivedQty,
            'total_using_qty': i.consumedQty,
            'uom_id': i.uomId ?? false,
            'return_qty': 0.0,
          }).toList();

      // 2) Create wizard, then read it back so we know the assigned
      //    line ids (needed for the write+confirm step).
      wizardId = await _provider.createReturnWizard(
        moId: moId,
        linePayloads: linePayloads,
      );
      final wizard = await _provider.readReturnWizard(wizardId);
      isMutating.value = false;

      if (wizard.lines.isEmpty) {
        AppNotify.warning(
          'Wizard rỗng',
          'Wizard trả vật tư không có dòng nào — vật tư có thể đã thay đổi.',
        );
        return;
      }

      // 3) Show modal — worker enters return_qty per line.
      final result = await Get.dialog<ReturnWizardResult>(
        ReturnWizardModal(
          wizard: wizard,
          moName: mo.value?.name ?? '',
        ),
        barrierDismissible: false,
      );
      if (result == null) return;

      // 4) Write line_ids + action_confirm. Server validates qty, releases
      //    reserved stock, decrements item.remain_qty.
      isMutating.value = true;
      await _provider.confirmReturnWizard(
        wizardId: wizardId,
        returnQtyByLineId: result.returnQtyByLineId,
      );
      final totalReturned = result.returnQtyByLineId.values
          .fold<double>(0, (a, b) => a + b);
      AppNotify.success(
        'Đã trả vật tư',
        'Tổng: ${totalReturned == totalReturned.truncateToDouble() ? totalReturned.toInt() : totalReturned.toStringAsFixed(2)}',
      );
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error(
        'Trả vật tư thất bại',
        e.message ?? 'Không gọi được máy chủ.',
      );
    } catch (e) {
      AppNotify.error('Trả vật tư thất bại', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> openQcHistory(ProductionModel production) async {
    if (isMutating.value) return;
    final isOqc = production.isLastLevel;
    isMutating.value = true;
    try {
      final records = await _provider.fetchQcHistory(
        productionId: production.id,
        isOqc: isOqc,
      );
      isMutating.value = false;
      if (records.isEmpty) {
        AppNotify.info(
          'Chưa có lịch sử',
          'Lot này chưa có bản ghi ${production.qcKind} nào.',
        );
        return;
      }
      await Get.dialog<void>(
        QcHistoryModal(production: production, records: records),
        barrierDismissible: true,
      );
    } on DioException catch (e) {
      AppNotify.error('Không tải được lịch sử',
          e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không tải được lịch sử', e.toString());
    } finally {
      isMutating.value = false;
    }
  }

  Future<void> deleteItem(int itemId) async {
    if (isMutating.value) return;
    final ok = await AppDialog.confirm(
      title: 'Xoá dòng vật tư',
      message: 'Xoá dòng này khỏi danh sách vật tư?',
      confirmLabel: 'Xoá',
    );
    if (!ok) return;
    isMutating.value = true;
    try {
      await _provider.deleteItem(itemId);
      selectedItemIds.remove(itemId);
      AppNotify.success('Đã xoá', 'Dòng vật tư đã được xoá.');
      await loadDetail();
    } on DioException catch (e) {
      AppNotify.error(
          'Không xoá được', e.message ?? 'Không gọi được máy chủ.');
    } catch (e) {
      AppNotify.error('Không xoá được', e.toString());
    } finally {
      isMutating.value = false;
    }
  }
}
