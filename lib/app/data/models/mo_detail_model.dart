import 'mo_item_model.dart';

class MoDetailModel {
  MoDetailModel({
    required this.id,
    required this.name,
    required this.state,
    required this.productName,
    required this.targetQty,
    required this.actualQty,
    required this.remainQty,
    required this.items,
    this.productCode,
    this.productSemiId,
    this.bomId,
    this.bomName,
    this.processName,
    this.sourceLocationName,
    this.destLocationName,
    this.workingLineName,
    this.workingLineStatus,
  });

  final int id;
  final String name;
  final String state;
  final String? productCode;
  final String productName;
  final double targetQty;
  final double actualQty;
  final double remainQty;
  final int? productSemiId;
  final int? bomId;
  final String? bomName;
  final String? processName;
  final String? sourceLocationName;
  final String? destLocationName;
  final String? workingLineName;
  final String? workingLineStatus;
  final List<MoItemModel> items;

  bool get isDraft => state == 'draft';
  bool get isInProgress => state == 'in_progress';
  bool get isDone => state == 'done';
  bool get isCancel => state == 'cancel';

  /// Whether `action_confirm_mo`
  bool get canConfirmMo => isDraft;

  /// `action_complete_mo`
  bool get canCompleteMo =>
      isInProgress &&
      actualQty >= targetQty &&
      items.every((i) => i.isConfirmed);

  double get progress {
    if (targetQty <= 0) return 0;
    final p = actualQty / targetQty;
    return p.clamp(0, 1).toDouble();
  }

  factory MoDetailModel.fromJson(
    Map<String, dynamic> json, {
    required List<MoItemModel> items,
  }) {
    final target = _toDouble(json['target_qty']);
    final actual = _toDouble(json['actual_qty']);
    return MoDetailModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'draft',
      productCode: _m2oName(json['product_id']),
      productName: json['product_name']?.toString() ??
          _m2oName(json['product_id']) ??
          '—',
      targetQty: target,
      actualQty: actual,
      remainQty: (target - actual).clamp(0, double.infinity).toDouble(),
      productSemiId: _m2oId(json['product_semi_id']),
      bomId: _m2oId(json['bom_id']),
      bomName: _m2oName(json['bom_id']),
      processName: _m2oName(json['process_id']),
      sourceLocationName: _m2oName(json['source_location_id']),
      destLocationName: _m2oName(json['dest_location_id']),
      workingLineName: _m2oName(json['working_line_id']),
      workingLineStatus: json['working_line_status'] is String
          ? json['working_line_status'] as String
          : null,
      items: items,
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
}
