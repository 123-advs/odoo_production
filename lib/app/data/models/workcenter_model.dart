class WorkcenterModel {
  WorkcenterModel({
    required this.id,
    required this.name,
    this.code,
    this.processId,
    this.processName,
    this.active = true,
  });

  final int id;
  final String name;
  final String? code;
  final int? processId;
  final String? processName;
  final bool active;

  factory WorkcenterModel.fromJson(Map<String, dynamic> json) {
    return WorkcenterModel(
      id: (json['id'] as num).toInt(),
      name: _str(json['name']) ?? '',
      code: _str(json['code']),
      processId: _m2oId(json['process_id']),
      processName: _m2oName(json['process_id']),
      active: json['active'] as bool? ?? true,
    );
  }

  static String? _str(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    return null;
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
}
