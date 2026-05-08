/// Row of `mrp.mo.item`. Lifecycle: `draft` (just scanned) → `confirm`
/// (after `action_confirm_items` reserves stock).
class MoItemModel {
  MoItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.lotId,
    required this.lotName,
    required this.uomId,
    required this.stockQty,
    required this.receivedQty,
    required this.consumedQty,
    required this.remainQty,
    required this.uom,
    required this.state,
    this.workcenterId,
    this.workcenterName,
    this.workerId,
    this.workerName,
  });

  final int id;
  final int? productId;
  final String productName;
  final int? lotId;
  final String lotName;
  final int? uomId;
  final double stockQty;
  final double receivedQty;
  final double consumedQty;
  final double remainQty;
  final String uom;
  final String state;
  final int? workcenterId;
  final String? workcenterName;
  final int? workerId;
  final String? workerName;

  bool get isDraft => state == 'draft';
  bool get isConfirmed => state == 'confirm';

  factory MoItemModel.fromJson(Map<String, dynamic> json) {
    return MoItemModel(
      id: (json['id'] as num).toInt(),
      productId: _m2oId(json['product_id']),
      productName: _str(json['product_name']) ??
          _m2oName(json['product_id']) ??
          '—',
      lotId: _m2oId(json['lot_id']),
      lotName: _m2oName(json['lot_id']) ?? '—',
      uomId: _m2oId(json['uom_id']),
      stockQty: _toDouble(json['stock_qty']),
      receivedQty: _toDouble(json['received_qty']),
      consumedQty: _toDouble(json['consumed_qty']),
      remainQty: _toDouble(json['remain_qty']),
      uom: _m2oName(json['uom_id']) ?? '',
      state: _str(json['state']) ?? 'draft',
      workcenterId: _m2oId(json['workcenter_id']),
      workcenterName: _m2oName(json['workcenter_id']),
      workerId: _m2oId(json['worker_id']),
      workerName: _m2oName(json['worker_id']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
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
