/// `mrp.mo` row in list views
///  `OdooProvider.fetchMoDetail`
class MoModel {
  MoModel({
    required this.id,
    required this.name,
    required this.state,
    this.productName,
    this.productCode,
    this.targetQty = 0,
    this.actualQty = 0,
    this.deliveryDate,
    this.workingLineId,
    this.workingLineName,
    this.workingLineStatus,
  });

  final int id;
  final String name;
  final String state; // draft | in_progress | done | cancel
  final String? productName;
  final String? productCode;
  final double targetQty;
  final double actualQty;
  final DateTime? deliveryDate;
  final int? workingLineId;
  final String? workingLineName;

  /// (`mrp.mo.working_line_status`):
  /// pending | waiting | ready | progress | done | cancel
  final String? workingLineStatus;

  double get progress {
    if (targetQty <= 0) return 0;
    final p = actualQty / targetQty;
    return p.clamp(0, 1).toDouble();
  }

  double get remainQty {
    final r = targetQty - actualQty;
    return r < 0 ? 0 : r;
  }

  factory MoModel.fromJson(Map<String, dynamic> json) {
    return MoModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'draft',
      productName: json['product_name']?.toString(),
      productCode: _m2oName(json['product_id']),
      targetQty: _toDouble(json['target_qty']),
      actualQty: _toDouble(json['actual_qty']),
      deliveryDate: _parseDate(json['delivery_date']),
      workingLineId: _m2oId(json['working_line_id']),
      workingLineName: _m2oName(json['working_line_id']),
      workingLineStatus: json['working_line_status'] is String
          ? json['working_line_status'] as String
          : null,
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

enum MoStateFilter { all, draft, inProgress, done }

extension MoStateFilterX on MoStateFilter {
  String get label => switch (this) {
        MoStateFilter.all => 'Tất cả',
        MoStateFilter.draft => 'Mới',
        MoStateFilter.inProgress => 'Đang chạy',
        MoStateFilter.done => 'Hoàn tất',
      };

  /// Odoo domain fragment to add to the search.
  /// Returns empty list for `all` (= no extra constraint).
  List<List<dynamic>> get domain => switch (this) {
        MoStateFilter.all => const [
            ['state', '!=', 'cancel'],
          ],
        MoStateFilter.draft => const [
            ['state', '=', 'draft'],
          ],
        MoStateFilter.inProgress => const [
            ['state', '=', 'in_progress'],
          ],
        MoStateFilter.done => const [
            ['state', '=', 'done'],
          ],
      };
}
