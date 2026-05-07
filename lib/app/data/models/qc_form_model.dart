/// QC form preview returned from `mrp.production.action_pqc` /
/// `action_oqc`. Server returns an `ir.actions.client` dict whose
/// `context` payload carries everything the form UI needs.
///
/// We keep the **raw** `context` map verbatim — `mes.qc_form.history.
/// create_history_*` expects an `inspectionData` payload mirroring the
/// original action context, plus the worker's edits. Holding it raw and
/// patching at submit time means we can never lose a key the server
/// originally emitted (form_id, staff_id, type_roll, category_material,
/// rev_no, isEMB, …).
class QcFormPreview {
  QcFormPreview({
    required this.rawContext,
    required this.checkList,
  });

  /// Verbatim copy of `action.context` from the server response.
  final Map<String, dynamic> rawContext;

  /// Parsed, mutable view of `rawContext['check_list']`. The worker
  /// edits these in the QC modal; we serialise them back into the
  /// inspectionData payload at apply time.
  final List<QcCheckItem> checkList;

  String get title => rawContext['title']?.toString() ?? 'QC Form';
  String? get materialCode => _str(rawContext['material_code']);
  String? get materialName => _str(rawContext['material_name']);
  String? get lineNo => _str(rawContext['line_no']);
  String? get lot => _str(rawContext['lot']);
  num? get qty => rawContext['qty'] is num ? rawContext['qty'] as num : null;
  String? get qtyUom => _str(rawContext['qty_uom']);
  String? get process => _str(rawContext['process']);
  String? get staffName => _str(rawContext['staff_name']);

  factory QcFormPreview.fromAction(Map<String, dynamic> action) {
    final ctx = (action['context'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final raw = (ctx['check_list'] as List?) ?? const [];
    return QcFormPreview(
      rawContext: ctx,
      checkList: raw
          .whereType<Map>()
          .map((e) => QcCheckItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Build the `inspectionData` payload for `create_history_pqc` /
  /// `create_history_oqc`. Merges user-entered totals + check_list over
  /// the raw context, fills server-derived fields (`defect_ratio`,
  /// `check_date`, `final_result`).
  Map<String, dynamic> toInspectionData({
    required double okQty,
    required double ngQty,
    required List<Map<String, dynamic>> checkListJson,
  }) {
    final qtyVal = (rawContext['qty'] as num?)?.toDouble() ?? 0.0;
    final samplingRaw =
        (rawContext['qty_sampling'] as num?)?.toDouble() ?? 0.0;
    final sampling = samplingRaw > 0 ? samplingRaw : (qtyVal > 0 ? qtyVal : 1);
    final defectRatio = sampling > 0
        ? (ngQty / sampling) * 100.0
        : 0.0;
    return <String, dynamic>{
      ...rawContext,
      'ok_qty': okQty,
      'ng_qty': ngQty,
      'qty': qtyVal,
      'qty_sampling': sampling,
      'defect_ratio': double.parse(defectRatio.toStringAsFixed(2)),
      'check_date': DateTime.now().toIso8601String().split('.').first,
      'final_result': ngQty > 0 ? 'NG' : 'OK',
      'check_list': checkListJson,
    };
  }

  static String? _str(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    return null;
  }
}

/// One persisted QC history record (`mes.qc_form.history`). Read-only —
/// shown via the "Xem lịch sử" button on production cards that have
/// already been through PQC / OQC.
class QcHistoryRecord {
  QcHistoryRecord({
    required this.id,
    required this.name,
    required this.checkList,
    this.checkDate,
    this.okQty,
    this.ngQty,
    this.qtySampling,
    this.defectRatio,
    this.staffName,
    this.overallResult,
  });

  final int id;
  final String name;
  final List<QcCheckItem> checkList;
  final DateTime? checkDate;
  final double? okQty;
  final double? ngQty;
  final double? qtySampling;
  final double? defectRatio;
  final String? staffName;
  final String? overallResult;

  factory QcHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    required List<QcCheckItem> checkList,
  }) {
    return QcHistoryRecord(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      checkList: checkList,
      checkDate: _parseDt(json['check_date']),
      okQty: _toDoubleOrNull(json['ok_qty']),
      ngQty: _toDoubleOrNull(json['ng_qty']),
      qtySampling: _toDoubleOrNull(json['qty_sampling']),
      defectRatio: _toDoubleOrNull(json['defect_ratio']),
      staffName: json['staff_name'] is String && json['staff_name'] != ''
          ? json['staff_name'] as String
          : null,
      overallResult:
          json['overall_result'] is String && json['overall_result'] != ''
              ? json['overall_result'] as String
              : null,
    );
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.isNotEmpty) return double.tryParse(v);
    return null;
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse('${v}Z')?.toLocal() ??
          DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }
}

/// One inspection checkpoint inside the QC form. The server sends a wide
/// schema (X1-X5 measurements, HD1-HD14 extra fields). Mobile MVP only
/// renders `result` (OK/NG) + `remark`; the rest is preserved verbatim
/// in `extra` so the JSON we send back keeps every key the server
/// originally sent.
class QcCheckItem {
  QcCheckItem({
    required this.id,
    required this.qcType,
    required this.qcProcess,
    required this.qcCode,
    required this.method,
    required this.frequency,
    required this.standard,
    required this.inputType,
    this.result = '',
    this.remark = '',
    Map<String, dynamic>? extra,
  }) : extra = extra ?? <String, dynamic>{};

  final int id;
  final String qcType;
  final String qcProcess;
  final String qcCode;
  final String method;
  final String frequency;
  final String standard;
  final String inputType; // 'ok_ng' | 'measurement' | ...

  /// Worker-entered result. For `ok_ng` inputs it's `'ok'` / `'ng'` /
  /// `''` (unset). For measurement inputs we leave it untouched and
  /// rely on `extra` for X1-X5 values.
  String result;
  String remark;

  /// All other keys from the server payload (X1-X5, HD1-HD14, mes_qc_*_id,
  /// pqc_worker_id, etc.). Mobile MVP doesn't edit these but echoes them
  /// back unchanged so the server doesn't lose state when we re-submit.
  final Map<String, dynamic> extra;

  bool get isOk => result.toLowerCase() == 'ok';
  bool get isNg => result.toLowerCase() == 'ng';
  bool get isOkNg => inputType == 'ok_ng';
  bool get isText => inputType == 'text';
  bool get isNumber => inputType == 'number';

  /// True when the worker has provided a value matching the input type.
  /// Used to gate the QC modal's confirm button.
  bool get isAnswered {
    switch (inputType) {
      case 'ok_ng':
        return isOk || isNg;
      case 'text':
      case 'number':
        return result.trim().isNotEmpty;
      default:
        return result.trim().isNotEmpty;
    }
  }

  factory QcCheckItem.fromJson(Map<String, dynamic> json) {
    const known = {
      'id',
      'qc_type',
      'qc_process',
      'qc_code',
      'method',
      'frequency',
      'standard',
      'input_type',
      'result',
      'remark',
    };
    final extra = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!known.contains(entry.key)) extra[entry.key] = entry.value;
    }
    return QcCheckItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      qcType: json['qc_type']?.toString() ?? '',
      qcProcess: json['qc_process']?.toString() ?? '',
      qcCode: json['qc_code']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      standard: json['standard']?.toString() ?? '',
      inputType: json['input_type']?.toString() ?? 'ok_ng',
      result: json['result']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      extra: extra,
    );
  }

  /// Serialise back into the same shape the server sent — preserves
  /// every original key plus the worker's edits.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'qc_type': qcType,
      'qc_process': qcProcess,
      'qc_code': qcCode,
      'method': method,
      'frequency': frequency,
      'standard': standard,
      'input_type': inputType,
      'result': result,
      'remark': remark,
      ...extra,
    };
  }
}
