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
  final double duration;
  final double durationExpected;
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

  bool get canStart => isReady || isPending;
  bool get canPause => isProgress;

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
