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
      return DateTime.tryParse('${v}Z')?.toLocal() ??
          DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }
}
