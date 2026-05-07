/// Lightweight DTO for `mrp.workorder` (extended in `tcs_mms_management_product`).
///
/// State machine (Odoo standard MRP): `pending` → `waiting` → `ready` →
/// `progress` → `done`, plus `cancel` from any state.
///   - **pending / waiting**: upstream not ready
///   - **ready**: ready to start (workers/materials available)
///   - **progress**: running, timer ticking server-side
///   - **done**: finished
///   - **cancel**: aborted
class WorkorderModel {
  WorkorderModel({
    required this.id,
    required this.name,
    required this.state,
    required this.duration,
    required this.durationExpected,
    required this.workerIds,
    this.workcenterId,
    this.workcenterName,
    this.dateStart,
  });

  final int id;
  final String name;
  final String state;
  /// Minutes already spent (server `duration`).
  final double duration;
  /// Estimated minutes (server `duration_expected`).
  final double durationExpected;
  /// IDs of `hr.employee` assigned to this workorder. `read` returns m2m
  /// fields as a flat list of ints — names would need a separate `name_get`.
  final List<int> workerIds;
  final int? workcenterId;
  final String? workcenterName;
  final DateTime? dateStart;

  bool get isReady => state == 'ready';
  bool get isProgress => state == 'progress';
  bool get isPending => state == 'pending' || state == 'waiting';
  bool get isDone => state == 'done';
  bool get isCancel => state == 'cancel';
  bool get isTerminal => isDone || isCancel;

  /// Whether `button_start` is callable now.
  bool get canStart => isReady || isPending;
  bool get canPause => isProgress;

  /// Hoàn tất is visible alongside Bắt đầu / Tạm dừng — server's
  /// `button_finish` is permissive (only checks remaining material; the
  /// underlying state-machine rejection bubbles up as a UserError if
  /// state isn't compatible). We surface the button on every non-terminal
  /// row so the worker can finish a workorder without first having to
  /// click Bắt đầu when items are already consumed elsewhere.
  bool get canFinish => !isTerminal;

  factory WorkorderModel.fromJson(Map<String, dynamic> json) {
    return WorkorderModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'pending',
      duration: _toDouble(json['duration']),
      durationExpected: _toDouble(json['duration_expected']),
      workerIds: _m2mIds(json['worker_ids']),
      workcenterId: _m2oId(json['workcenter_id']),
      workcenterName: _m2oName(json['workcenter_id']),
      dateStart: _parseDt(json['date_start']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int? _m2oId(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is num) {
      return (v.first as num).toInt();
    }
    return null;
  }

  static String? _m2oName(dynamic v) {
    if (v is List && v.length >= 2) return v[1]?.toString();
    return null;
  }

  /// `worker_ids` from `read` is a flat list of ints. Use this list to
  /// match against the current user's `hr.employee.id` for filtering.
  static List<int> _m2mIds(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<num>().map((e) => e.toInt()).toList();
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      // Odoo stores UTC without timezone marker; parse and treat as UTC.
      final parsed = DateTime.tryParse(v);
      return parsed?.toLocal();
    }
    return null;
  }
}
