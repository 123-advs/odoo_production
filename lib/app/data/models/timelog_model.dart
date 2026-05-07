/// Row of `mrp.timelogs` — a per-event log produced by the OEE wizard.
///
/// Two flavours, distinguished by which timestamp is set:
///   - **start** event (`startDate != null`, `endDate == null`): worker
///     pressed Bắt đầu.
///   - **end** event (`endDate != null`, `startDate == null`): worker
///     pressed Tạm dừng.
///
/// `issue` carries the picked `standard.issue.name` (or null for the
/// Operation default).
class TimelogModel {
  TimelogModel({
    required this.id,
    this.workcenterName,
    this.workerName,
    this.startDate,
    this.endDate,
    this.issue,
    this.issueDate,
  });

  final int id;
  final String? workcenterName;
  final String? workerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? issue;
  final DateTime? issueDate;

  bool get isStart => startDate != null && endDate == null;
  bool get isEnd => endDate != null && startDate == null;

  /// Best-effort timestamp shown on the event card. Falls back through
  /// `issue_date → start_date → end_date`.
  DateTime? get timestamp => issueDate ?? startDate ?? endDate;

  factory TimelogModel.fromJson(Map<String, dynamic> json) {
    return TimelogModel(
      id: (json['id'] as num).toInt(),
      workcenterName: _m2oName(json['workcenter_id']),
      workerName: _m2oName(json['worker_id']),
      startDate: _parseDt(json['start_date']),
      endDate: _parseDt(json['end_date']),
      issue: _str(json['issue']),
      issueDate: _parseDt(json['issue_date']),
    );
  }

  static String? _str(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  static String? _m2oName(dynamic v) {
    if (v is List && v.length >= 2) return v[1]?.toString();
    return null;
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      // Odoo stores UTC without timezone marker — parse as UTC then to local.
      return DateTime.tryParse('${v}Z')?.toLocal() ??
          DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }
}
