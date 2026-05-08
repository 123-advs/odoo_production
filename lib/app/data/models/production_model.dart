/// Row of `mrp.production` (a "satellite" production created by the
/// actual-qty wizard, holding produced lot + qty + QC state).
///
/// Lifecycle:
///   - **draft**: just created via actual wizard, awaiting QC
///   - **done**: PQC or OQC applied (computed by `_compute_state` when
///     `pqc_status='pqc'` or `oqc_status='oqc'`)
///
/// QC kind:
///   - PQC = Production Quality Check (intermediate)
///   - OQC = Outgoing Quality Check (final-level only — `is_last_level`)
class ProductionModel {
  ProductionModel({
    required this.id,
    required this.lotName,
    required this.actualQty,
    required this.okQty,
    required this.ngQty,
    required this.state,
    required this.pqcStatus,
    required this.oqcStatus,
    required this.isLastLevel,
    this.workcenterId,
    this.workcenterName,
    this.actualDate,
  });

  final int id;
  final String lotName;
  final double actualQty;
  final double okQty;
  final double ngQty;
  final String state;
  final String pqcStatus; // draft | pqc
  final String oqcStatus; // draft | oqc
  final bool isLastLevel;
  final int? workcenterId;
  final String? workcenterName;
  final DateTime? actualDate;

  bool get pqcDone => pqcStatus == 'pqc';
  bool get oqcDone => oqcStatus == 'oqc';

  /// True when this row needs PQC (or OQC if last level).
  bool get needsQc =>
      isLastLevel ? !oqcDone : !pqcDone;

  /// Worker can delete the row only while QC hasn't been recorded yet.
  /// Once PQC/OQC is applied, FG quants are written and lots are issued
  /// — deleting then would require a more involved rollback that the
  /// shop-floor flow doesn't support.
  bool get canDelete => !pqcDone && !oqcDone;

  String get qcKind => isLastLevel ? 'OQC' : 'PQC';

  factory ProductionModel.fromJson(Map<String, dynamic> json) {
    return ProductionModel(
      id: (json['id'] as num).toInt(),
      lotName: _m2oName(json['lot_id']) ?? '—',
      actualQty: _toDouble(json['actual_qty']),
      okQty: _toDouble(json['ok_qty']),
      ngQty: _toDouble(json['ng_qty']),
      state: json['state']?.toString() ?? 'draft',
      pqcStatus: json['pqc_status']?.toString() ?? 'draft',
      oqcStatus: json['oqc_status']?.toString() ?? 'draft',
      isLastLevel: json['is_last_level'] == true,
      workcenterId: _m2oId(json['workcenter_id']),
      workcenterName: _m2oName(json['workcenter_id']),
      actualDate: _parseDate(json['actual_date']),
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

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
