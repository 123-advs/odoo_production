import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/actual_wizard_model.dart';
import '../models/attachment_model.dart';
import '../models/bom_info_model.dart';
import '../models/issue_model.dart';
import '../models/mo_detail_model.dart';
import '../models/mo_item_model.dart';
import '../models/mo_model.dart';
import '../models/production_model.dart';
import '../models/qc_form_model.dart';
import '../models/return_wizard_model.dart';
import '../models/timelog_model.dart';
import '../models/workcenter_model.dart';
import '../models/workorder_model.dart';

/// Single entry point for all Odoo JSON-RPC. Wraps `/web/session/authenticate`
/// and `/web/dataset/call_kw`. Session cookie injection is handled by the
/// `_AuthInterceptor` in `ApiService`, so callers never set headers manually.
class OdooProvider {
  Dio get _dio => Get.find<ApiService>().dio;
  StorageService get _storage => Get.find<StorageService>();

  // ----- Auth -----

  Future<int?> login({
    required String login,
    required String password,
  }) async {
    final res = await _dio.post(
      '/web/session/authenticate',
      data: {
        'jsonrpc': '2.0',
        'params': {
          'db': ApiConstants.odooDatabase,
          'login': login,
          'password': password,
        },
      },
    );
    final result = res.data['result'];
    final uid = result?['uid'];
    if (uid is! int) return null;

    final cookies = res.headers.map['set-cookie'] ?? const <String>[];
    for (final c in cookies) {
      final m = RegExp(r'session_id=([^;]+)').firstMatch(c);
      if (m != null) {
        await _storage.writeSessionId(m.group(1)!);
        break;
      }
    }
    await _storage.setUserId(uid);
    final name = result?['name']?.toString();
    if (name != null) await _storage.setUserName(name);

    final empId = await _fetchEmployeeIdFor(uid);
    await _storage.setEmployeeId(empId);

    return uid;
  }

  Future<int?> _fetchEmployeeIdFor(int userId) async {
    final result = await callKw(
      model: 'hr.employee',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['user_id', '=', userId],
        ],
        'fields': ['id'],
        'limit': 1,
      },
    );
    if (result is List && result.isNotEmpty) {
      final row = result.first as Map<String, dynamic>;
      final raw = row['id'];
      if (raw is num) return raw.toInt();
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        '/web/session/destroy',
        data: {'jsonrpc': '2.0', 'params': {}},
      );
    } catch (_) {
      // best-effort: even if server-side destroy fails, local clear still runs
    }
    await _storage.clearSession();
  }

  // ----- Workcenters -----

  Future<List<WorkcenterModel>> fetchWorkcenters() async {
    final result = await callKw(
      model: 'mrp.workcenter',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['active', '=', true],
        ],
        'fields': ['id', 'name', 'code', 'active', 'process_id'],
        'order': 'process_id asc, name asc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(WorkcenterModel.fromJson)
          .toList();
    }
    return const [];
  }

  // ----- MO list -----

  /// Fetch MOs filtered by **process** (preferred) or by working line.
  ///
  /// Default behaviour scopes MOs to the worker's process (`mrp.mo.process_id
  /// == processId`) so a worker on Line 1 of "EMB (SW.H)" sees every MO
  /// flowing through that process — not just MOs already assigned to Line 1.
  /// Falls back to `working_line_id` when `processId` is null (e.g. when
  /// the picked workcenter has no process configured).
  Future<List<MoModel>> fetchMoList({
    required int workcenterId,
    int? processId,
    required MoStateFilter filter,
    int limit = 100,
  }) async {
    final scope = processId != null
        ? ['process_id', '=', processId]
        : ['working_line_id', '=', workcenterId];
    final domain = <List<dynamic>>[
      scope,
      ...filter.domain,
    ];
    final result = await callKw(
      model: 'mrp.mo',
      method: 'search_read',
      kwargs: {
        'domain': domain,
        'fields': [
          'id',
          'name',
          'state',
          'product_id',
          'product_name',
          'target_qty',
          'actual_qty',
          'delivery_date',
          'working_line_id',
          'working_line_status',
        ],
        'order': 'delivery_date asc, id desc',
        'limit': limit,
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(MoModel.fromJson)
          .toList();
    }
    return const [];
  }

  // ----- MO detail -----

  Future<MoDetailModel> fetchMoDetail(int moId) async {
    final moResult = await callKw(
      model: 'mrp.mo',
      method: 'read',
      args: [
        [moId],
      ],
      kwargs: {
        'fields': [
          'id',
          'name',
          'state',
          'product_id',
          'product_name',
          'product_semi_id',
          'target_qty',
          'actual_qty',
          'bom_id',
          'process_id',
          'source_location_id',
          'dest_location_id',
          'working_line_id',
          'working_line_status',
          'item_ids',
        ],
      },
    );
    if (moResult is! List || moResult.isEmpty) {
      throw StateError('MO $moId không tồn tại');
    }
    final mo = moResult.first as Map<String, dynamic>;

    final itemIds = (mo['item_ids'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ?? <int>[];
    final items = await fetchMoItems(itemIds);

    return MoDetailModel.fromJson(mo, items: items);
  }

  Future<List<MoItemModel>> fetchMoItems(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final result = await callKw(
      model: 'mrp.mo.item',
      method: 'read',
      args: [ids],
      kwargs: {
        'fields': [
          'id',
          'product_id',
          'product_name',
          'lot_id',
          'stock_qty',
          'received_qty',
          'consumed_qty',
          'remain_qty',
          'uom_id',
          'state',
          'workcenter_id',
          'worker_id',
        ],
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(MoItemModel.fromJson)
          .toList();
    }
    return const [];
  }

  // ----- MO actions -----

  Future<void> confirmMo(int moId) async {
    await callKw(
      model: 'mrp.mo',
      method: 'action_confirm_mo',
      args: [
        [moId],
      ],
    );
  }

  Future<void> completeMo(int moId) async {
    await callKw(
      model: 'mrp.mo',
      method: 'action_complete_mo',
      args: [
        [moId],
      ],
    );
  }

  /// Server-side `action_scan_lot` reads `self.scan_workcenter_id` from the MO
  /// row, so we must write the workcenter on the MO before the scan call.
  /// Two RPCs (write + action) is intentional — wrapping both in a single
  /// call would require a custom controller, deferred until Slice 4+.
  Future<void> scanItemLot({
    required int moId,
    required String lotName,
    required int workcenterId,
  }) async {
    await callKw(
      model: 'mrp.mo',
      method: 'write',
      args: [
        [moId],
        {'scan_workcenter_id': workcenterId},
      ],
    );
    await callKw(
      model: 'mrp.mo',
      method: 'action_scan_lot',
      args: [
        [moId],
      ],
      kwargs: {'lot_name': lotName},
    );
  }

  /// `action_confirm_items` reads `selected_ids` from `self.env.context`.
  /// Pass them via the JSON-RPC `kwargs.context` channel so Odoo merges them
  /// into the env context for the call.
  Future<void> confirmItems({
    required int moId,
    required List<int> itemIds,
  }) async {
    await callKw(
      model: 'mrp.mo',
      method: 'action_confirm_items',
      args: [
        [moId],
      ],
      kwargs: {
        'context': {'selected_ids': itemIds},
      },
    );
  }

  // ----- Workorders -----

  Future<List<WorkorderModel>> fetchWorkorders(int moId) async {
    final result = await callKw(
      model: 'mrp.workorder',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['mo_id', '=', moId],
        ],
        'fields': [
          'id',
          'name',
          'state',
          'duration',
          'duration_expected',
          'worker_ids',
          'workcenter_id',
          'date_start',
        ],
        'order': 'id asc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(WorkorderModel.fromJson)
          .toList();
    }
    return const [];
  }

  /// Server-side `button_start` opens an OEE wizard by default. We bypass it
  /// via `context.skip_oee_wizard=True` so the call resolves to a state
  /// transition without returning an action dict the client can't render.
  /// Slice 5 will add a proper OEE issue picker for `pause`.
  Future<void> startWorkorder(int workorderId) async {
    await callKw(
      model: 'mrp.workorder',
      method: 'button_start',
      args: [
        [workorderId],
      ],
      kwargs: {
        'context': {'skip_oee_wizard': true},
      },
    );
  }

  Future<void> pauseWorkorder(int workorderId) async {
    await callKw(
      model: 'mrp.workorder',
      method: 'button_pending',
      args: [
        [workorderId],
      ],
      kwargs: {
        'context': {'skip_oee_wizard': true},
      },
    );
  }

  Future<void> finishWorkorder(int workorderId) async {
    await callKw(
      model: 'mrp.workorder',
      method: 'button_finish',
      args: [
        [workorderId],
      ],
    );
  }

  // ----- Productions (mrp.production) + QC -----

  Future<List<ProductionModel>> fetchProductions(int moId) async {
    final result = await callKw(
      model: 'mrp.production',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['mo_id', '=', moId],
        ],
        'fields': [
          'id',
          'lot_id',
          'actual_qty',
          'ok_qty',
          'ng_qty',
          'state',
          'pqc_status',
          'oqc_status',
          'is_last_level',
          'workcenter_id',
          'actual_date',
        ],
        'order': 'actual_date desc, id desc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(ProductionModel.fromJson)
          .toList();
    }
    return const [];
  }

  /// Fetch the QC form preview for a production. Calls the public
  /// `action_pqc` / `action_oqc` (they return `ir.actions.client` dicts
  /// whose `context` carries the form payload — including `check_list`).
  Future<QcFormPreview> previewQcForm({
    required int productionId,
    required bool isOqc,
  }) async {
    final method = isOqc ? 'action_oqc' : 'action_pqc';
    final result = await callKw(
      model: 'mrp.production',
      method: method,
      args: [
        [productionId],
      ],
    );
    if (result is Map) {
      return QcFormPreview.fromAction(result.cast<String, dynamic>());
    }
    throw StateError('Không tải được biểu mẫu kiểm tra ${isOqc ? "OQC" : "PQC"}');
  }

  /// Direct PQC apply — bypasses Odoo's form-based `action_pqc` (which
  /// returns an action dict for a JS QC form). `apply_pqc_result` writes
  /// ok_qty/ng_qty, persists `check_list` JSON, updates lots, marks
  /// `pqc_status='pqc'` and finishes the active workorder.
  Future<void> applyPqc({
    required int productionId,
    required double okQty,
    required double ngQty,
    List<Map<String, dynamic>>? checkList,
  }) async {
    await callKw(
      model: 'mrp.production',
      method: 'apply_pqc_result',
      args: [
        [productionId],
      ],
      kwargs: {
        'ok_qty': okQty,
        'ng_qty': ngQty,
        'check_list': ?checkList,
      },
    );
  }

  Future<void> applyOqc({
    required int productionId,
    required double okQty,
    required double ngQty,
    List<Map<String, dynamic>>? checkList,
  }) async {
    await callKw(
      model: 'mrp.production',
      method: 'apply_oqc_result',
      args: [
        [productionId],
      ],
      kwargs: {
        'ok_qty': okQty,
        'ng_qty': ngQty,
        'check_list': ?checkList,
      },
    );
  }

  /// Persist a QC inspection history record. Mirrors the second RPC
  /// the MMS web frontend issues after `apply_*_result` — without it,
  /// the inspection results live only on the production row and can't
  /// be browsed via the QC history view.
  Future<void> createQcHistory({
    required Map<String, dynamic> inspectionData,
    required bool isOqc,
  }) async {
    final method = isOqc ? 'create_history_oqc' : 'create_history_pqc';
    await callKw(
      model: 'mes.qc_form.history',
      method: method,
      args: const [],
      kwargs: {'inspectionData': inspectionData},
    );
  }

  /// Browse past QC inspections for a production. Two RPCs:
  ///   1. `search_read` history records by production + form_type
  ///   2. For each history, call public `prepare_check_list_data_history`
  ///      which returns the assembled check_list with each line's
  ///      question metadata (qc_type, qc_process, qc_code, method, …)
  ///      and the result/remark filled in by the inspector.
  Future<List<QcHistoryRecord>> fetchQcHistory({
    required int productionId,
    required bool isOqc,
  }) async {
    final formType = isOqc ? 'oqc' : 'pqc';
    final histResult = await callKw(
      model: 'mes.qc_form.history',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['mrp_production_id', '=', productionId],
          ['form_type', '=', formType],
        ],
        'fields': [
          'id',
          'name',
          'check_date',
          'ok_qty',
          'ng_qty',
          'qty_sampling',
          'defect_ratio',
          'staff_name',
          'overall_result',
        ],
        'order': 'check_date desc, id desc',
      },
    );
    if (histResult is! List || histResult.isEmpty) return const [];

    final records = <QcHistoryRecord>[];
    for (final raw in histResult.whereType<Map<String, dynamic>>()) {
      final id = (raw['id'] as num).toInt();
      final lines = await callKw(
        model: 'mes.qc_form.history',
        method: 'prepare_check_list_data_history',
        args: [
          [id],
        ],
      );
      final items = <QcCheckItem>[];
      if (lines is List) {
        for (final l in lines.whereType<Map>()) {
          items.add(QcCheckItem.fromJson(l.cast<String, dynamic>()));
        }
      }
      records.add(QcHistoryRecord.fromJson(raw, checkList: items));
    }
    return records;
  }

  // ----- BOM (for client-side material breakdown) -----

  Future<BomInfoModel?> fetchBomInfo(int bomId) async {
    final bomResult = await callKw(
      model: 'mrp.bom',
      method: 'read',
      args: [
        [bomId],
      ],
      kwargs: {
        'fields': ['id', 'product_qty', 'bom_line_ids'],
      },
    );
    if (bomResult is! List || bomResult.isEmpty) return null;
    final bom = bomResult.first as Map<String, dynamic>;
    final lineIds = (bom['bom_line_ids'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList() ??
        const <int>[];
    final productQty = (bom['product_qty'] as num?)?.toDouble() ?? 0;
    if (lineIds.isEmpty) {
      return BomInfoModel(
        id: bomId,
        productQty: productQty,
        lines: const [],
      );
    }
    final linesResult = await callKw(
      model: 'mrp.bom.line',
      method: 'read',
      args: [lineIds],
      kwargs: {
        'fields': ['id', 'product_id', 'required_qty'],
      },
    );
    final lines = linesResult is List
        ? linesResult
            .whereType<Map<String, dynamic>>()
            .map(BomLineInfo.fromJson)
            .toList()
        : <BomLineInfo>[];
    return BomInfoModel(
      id: bomId,
      productQty: productQty,
      lines: lines,
    );
  }

  // ----- Actual qty wizard -----

  /// Create the actual-qty wizard with a precomputed payload. Mirrors
  /// `mrp.mo.actual.wizard._build_and_create` server-side, but goes through
  /// the public `create` method (Odoo's JSON-RPC layer rejects calls to
  /// methods starting with `_`).
  ///
  /// Caller is responsible for filtering items to those eligible for this
  /// workcenter + worker (state='confirm', remain_qty > 0) and computing
  /// `remain_qty` = target_qty − Σ(production.actual_qty for this workcenter).
  Future<int> createActualWizard({
    required int moId,
    required int workcenterId,
    required int? workerId,
    required int? productSemiId,
    required double targetQty,
    required double remainQty,
    required List<Map<String, dynamic>> linePayloads,
  }) async {
    if (linePayloads.isEmpty) {
      throw StateError(
          'Không có vật tư nào đã xác nhận và còn dư cho dây chuyền + công nhân hiện tại.');
    }
    final result = await callKw(
      model: 'mrp.mo.actual.wizard',
      method: 'create',
      args: [
        {
          'mo_id': moId,
          'workcenter_id': workcenterId,
          'worker_id': ?workerId,
          'product_semi_id': ?productSemiId,
          'target_qty': targetQty,
          'remain_qty': remainQty,
          'line_ids': linePayloads.map((p) => [0, 0, p]).toList(),
        },
      ],
    );
    if (result is num) return result.toInt();
    if (result is List && result.isNotEmpty && result.first is num) {
      return (result.first as num).toInt();
    }
    throw StateError('Không tạo được wizard nhập sản lượng.');
  }

  Future<ActualWizardModel> readActualWizard(int wizardId) async {
    final wResult = await callKw(
      model: 'mrp.mo.actual.wizard',
      method: 'read',
      args: [
        [wizardId],
      ],
      kwargs: {
        'fields': [
          'id',
          'target_qty',
          'remain_qty',
          'product_semi_name',
          'line_ids',
        ],
      },
    );
    if (wResult is! List || wResult.isEmpty) {
      throw StateError('Wizard $wizardId không tồn tại');
    }
    final w = wResult.first as Map<String, dynamic>;
    final lineIds = (w['line_ids'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList() ??
        const <int>[];
    final lines = await _readActualWizardLines(lineIds);
    return ActualWizardModel.fromJson(w, lines: lines);
  }

  Future<List<ActualWizardLine>> _readActualWizardLines(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final result = await callKw(
      model: 'mrp.mo.actual.wizard.line',
      method: 'read',
      args: [ids],
      kwargs: {
        'fields': [
          'id',
          'product_id',
          'product_name',
          'lot_id',
          'received_qty',
          'remain_qty',
          'uom_id',
          'using_qty',
          'other_loss',
        ],
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(ActualWizardLine.fromJson)
          .toList();
    }
    return const [];
  }

  /// Push computed `using_qty` + `other_loss` per line + `actual_qty` on
  /// the wizard, then confirm. Server's `action_confirm` validates each
  /// `using_qty <= remain_qty` and at least one line per BOM material > 0.
  Future<void> confirmActualWizard({
    required int wizardId,
    required double actualQty,
    required Map<int, double> usingQtyByLineId,
    Map<int, double>? otherLossByLineId,
  }) async {
    final losses = otherLossByLineId ?? const <int, double>{};
    // Write actual_qty + line_ids in one RPC. Odoo Many2many/One2many
    // command (1, id, vals) means "update existing record". Merge using_qty
    // and other_loss for the same line into a single update payload.
    final lineIds = <int>{...usingQtyByLineId.keys, ...losses.keys};
    final lineCommands = lineIds.map((id) {
      final vals = <String, dynamic>{};
      if (usingQtyByLineId.containsKey(id)) {
        vals['using_qty'] = usingQtyByLineId[id];
      }
      if (losses.containsKey(id)) {
        vals['other_loss'] = losses[id];
      }
      return [1, id, vals];
    }).toList();
    await callKw(
      model: 'mrp.mo.actual.wizard',
      method: 'write',
      args: [
        [wizardId],
        {
          'actual_qty': actualQty,
          'line_ids': lineCommands,
        },
      ],
    );
    await callKw(
      model: 'mrp.mo.actual.wizard',
      method: 'action_confirm',
      args: [
        [wizardId],
      ],
    );
  }

  // ----- OEE / DownTime -----

  /// Fetch issues filtered by `operating_status`:
  ///   - `on`  → "good" reasons used at start
  ///   - `off` → downtime reasons used at pause
  Future<List<IssueModel>> fetchIssues(String operatingStatus) async {
    final result = await callKw(
      model: 'standard.issue',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['operating_status', '=', operatingStatus],
        ],
        'fields': ['id', 'code', 'name', 'operating_status'],
        'order': 'code asc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(IssueModel.fromJson)
          .toList();
    }
    return const [];
  }

  /// Run an OEE wizard step (start or pause) for a workorder. Server
  /// `action_confirm` is symmetric — it inspects `wo.state` to decide:
  ///   - state != progress → opens timelog + productivity-productive
  ///     record, then `button_start(skip_oee_wizard=True)`
  ///   - state == progress → closes productive with downtime reason,
  ///     then `button_pending(skip_oee_wizard=True)`
  ///
  /// Caller picks the right `issueId` by fetching `standard.issue` filtered
  /// by `operating_status`: `on` for start, `off` for pause.
  Future<void> submitOeeWizard({
    required int workorderId,
    required int? employeeId,
    required int issueId,
  }) async {
    final wizardCreate = await callKw(
      model: 'mrp.oee.wizard',
      method: 'create',
      args: [
        {
          'workorder_id': workorderId,
          'worker_id': ?employeeId,
          'issue_id': issueId,
        },
      ],
    );
    final wizardId = wizardCreate is num
        ? wizardCreate.toInt()
        : (wizardCreate as List).first as int;
    await callKw(
      model: 'mrp.oee.wizard',
      method: 'action_confirm',
      args: [
        [wizardId],
      ],
    );
  }

  // ----- Document attachments -----

  Future<List<TimelogModel>> fetchTimelogs(int moId) async {
    final result = await callKw(
      model: 'mrp.timelogs',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['mo_id', '=', moId],
        ],
        'fields': [
          'id',
          'workcenter_id',
          'worker_id',
          'start_date',
          'end_date',
          'issue',
          'issue_date',
        ],
        'order': 'issue_date desc, id desc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(TimelogModel.fromJson)
          .toList();
    }
    return const [];
  }

  Future<List<AttachmentModel>> fetchAttachments(int moId) async {
    final result = await callKw(
      model: 'mrp.mo.attachment',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['mo_id', '=', moId],
        ],
        'fields': ['id', 'file_name', 'remark', 'upload_by', 'upload_date'],
        'order': 'upload_date desc, id desc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(AttachmentModel.fromJson)
          .toList();
    }
    return const [];
  }

  /// Two RPCs: create the upload wizard with file (base64) + metadata,
  /// then call `action_upload`. Server creates `mrp.mo.attachment` and
  /// also pushes the file into the KMS Documents folder for archival.
  Future<void> uploadAttachment({
    required int moId,
    required String fileName,
    required String base64Data,
    String? remark,
  }) async {
    final wizardCreate = await callKw(
      model: 'mrp.mo.upload.wizard',
      method: 'create',
      args: [
        {
          'mo_id': moId,
          'file_name': fileName,
          'file': base64Data,
          if (remark != null && remark.isNotEmpty) 'remark': remark,
        },
      ],
    );
    final wizardId = wizardCreate is num
        ? wizardCreate.toInt()
        : (wizardCreate as List).first as int;
    await callKw(
      model: 'mrp.mo.upload.wizard',
      method: 'action_upload',
      args: [
        [wizardId],
      ],
    );
  }

  Future<bool> deleteAttachment(int attachmentId) async {
    final result = await callKw(
      model: 'mrp.mo.attachment',
      method: 'unlink',
      args: [
        [attachmentId],
      ],
    );
    return result == true;
  }

  // ----- Return material wizard -----

  /// Create the return wizard with prebuilt line payloads. Mirrors
  /// `mrp.mo.return.wizard._build_and_create` on the server (private
  /// → not callable via JSON-RPC) by going through public `create`.
  /// Caller filters eligible items (state='confirm' + remain_qty > 0).
  Future<int> createReturnWizard({
    required int moId,
    required List<Map<String, dynamic>> linePayloads,
  }) async {
    if (linePayloads.isEmpty) {
      throw StateError('Không có vật tư còn dư để trả.');
    }
    final result = await callKw(
      model: 'mrp.mo.return.wizard',
      method: 'create',
      args: [
        {
          'mo_id': moId,
          'line_ids': linePayloads.map((p) => [0, 0, p]).toList(),
        },
      ],
    );
    if (result is num) return result.toInt();
    if (result is List && result.isNotEmpty && result.first is num) {
      return (result.first as num).toInt();
    }
    throw StateError('Không tạo được wizard trả vật tư.');
  }

  Future<ReturnWizardModel> readReturnWizard(int wizardId) async {
    final wResult = await callKw(
      model: 'mrp.mo.return.wizard',
      method: 'read',
      args: [
        [wizardId],
      ],
      kwargs: {
        'fields': ['id', 'line_ids'],
      },
    );
    if (wResult is! List || wResult.isEmpty) {
      throw StateError('Wizard $wizardId không tồn tại');
    }
    final w = wResult.first as Map<String, dynamic>;
    final lineIds = (w['line_ids'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList() ??
        const <int>[];
    final lines = await _readReturnWizardLines(lineIds);
    return ReturnWizardModel(id: (w['id'] as num).toInt(), lines: lines);
  }

  Future<List<ReturnWizardLine>> _readReturnWizardLines(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final result = await callKw(
      model: 'mrp.mo.return.wizard.line',
      method: 'read',
      args: [ids],
      kwargs: {
        'fields': [
          'id',
          'item_id',
          'product_id',
          'product_name',
          'lot_id',
          'remain_qty',
          'received_qty',
          'total_using_qty',
          'uom_id',
          'return_qty',
        ],
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(ReturnWizardLine.fromJson)
          .toList();
    }
    return const [];
  }

  /// Push `return_qty` per line and confirm. Server `action_confirm`
  /// validates `return_qty <= remain_qty`, releases reserved stock at
  /// the source location, and decrements `item.remain_qty`. Lines with
  /// `return_qty == 0` are silently skipped server-side.
  Future<void> confirmReturnWizard({
    required int wizardId,
    required Map<int, double> returnQtyByLineId,
  }) async {
    final lineCommands = returnQtyByLineId.entries
        .map((e) => [1, e.key, {'return_qty': e.value}])
        .toList();
    if (lineCommands.isNotEmpty) {
      await callKw(
        model: 'mrp.mo.return.wizard',
        method: 'write',
        args: [
          [wizardId],
          {'line_ids': lineCommands},
        ],
      );
    }
    await callKw(
      model: 'mrp.mo.return.wizard',
      method: 'action_confirm',
      args: [
        [wizardId],
      ],
    );
  }

  Future<bool> deleteItem(int itemId) async {
    final result = await callKw(
      model: 'mrp.mo.item',
      method: 'unlink',
      args: [
        [itemId],
      ],
    );
    return result == true;
  }

  /// Write `received_qty` on a draft item line. Server `_check_received_qty
  /// _not_exceed_stock` will reject any value over `stock_qty`.
  Future<void> setItemReceivedQty({
    required int itemId,
    required double qty,
  }) async {
    await callKw(
      model: 'mrp.mo.item',
      method: 'write',
      args: [
        [itemId],
        {'received_qty': qty},
      ],
    );
  }

  // ----- Generic call_kw -----

  Future<dynamic> callKw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final res = await _dio.post(
      '/web/dataset/call_kw',
      data: {
        'jsonrpc': '2.0',
        'params': {
          'model': model,
          'method': method,
          'args': args,
          'kwargs': kwargs,
        },
      },
    );
    final data = res.data;
    if (data['error'] != null) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: data['error']['data']?['message'] ?? data['error']['message'],
      );
    }
    return data['result'];
  }
}
