class WorkorderModel {
  WorkorderModel({
    required this.id,
    required this.name,
    required this.state,
    required this.duration,
    required this.durationExpected,
    required this.workerIds,
    required this.workerNames,
    required this.equipmentIds,
    required this.equipmentNames,
    this.workcenterId,
    this.workcenterName,
    this.dateStart,
  });

  final int id;
  final String name;
  final String state;
  final double duration;
  final double durationExpected;
  final List<int> workerIds;
  /// Resolved display names for `workerIds`, in the same order. Empty
  /// when the provider didn't (or couldn't) batch-read names.
  final List<String> workerNames;
  /// IDs of `maintenance.equipment` attached to this workorder (server
  /// computes this from `workcenter_id.equipment_ids`).
  final List<int> equipmentIds;
  /// Resolved display names for `equipmentIds`, in the same order. Empty
  /// when the provider didn't (or couldn't) batch-read names.
  final List<String> equipmentNames;
  final int? workcenterId;
  final String? workcenterName;
  final DateTime? dateStart;

  bool get isReady => state == 'ready';
  bool get isProgress => state == 'progress';
  bool get isPending => state == 'pending' || state == 'waiting';
  bool get isDone => state == 'done';
  bool get isCancel => state == 'cancel';
  bool get isTerminal => isDone || isCancel;

  bool get canStart => isReady || isPending;
  bool get canPause => isProgress;

  /// Hoàn tất chỉ hiện khi line đã ở trạng thái dừng (ready/pending/waiting)
  /// — buộc worker phải nhấn Tạm dừng trước, để OEE-issue wizard ghi
  /// nhận lý do dừng máy. Server `button_finish` cũng raise UserError
  /// nếu state vẫn là `progress`, đây là defense-in-depth UX.
  bool get canFinish => !isTerminal && !isProgress;

  factory WorkorderModel.fromJson(
    Map<String, dynamic> json, {
    Map<int, String> workerNamesById = const {},
    Map<int, String> equipmentNamesById = const {},
  }) {
    final wIds = _m2mIds(json['worker_ids']);
    final equipIds = _m2mIds(json['equipment_ids']);
    return WorkorderModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'pending',
      duration: _toDouble(json['duration']),
      durationExpected: _toDouble(json['duration_expected']),
      workerIds: wIds,
      workerNames: wIds
          .map((id) => workerNamesById[id])
          .whereType<String>()
          .toList(),
      equipmentIds: equipIds,
      equipmentNames: equipIds
          .map((id) => equipmentNamesById[id])
          .whereType<String>()
          .toList(),
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

  static List<int> _m2mIds(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<num>().map((e) => e.toInt()).toList();
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      final parsed = DateTime.tryParse(v);
      return parsed?.toLocal();
    }
    return null;
  }
}
