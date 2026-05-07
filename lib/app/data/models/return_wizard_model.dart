/// Snapshot of `mrp.mo.return.wizard` after `create`. Server's
/// `_build_and_create` is private (JSON-RPC blocks `_` methods), so we
/// build the line_ids client-side and call public `create` directly —
/// same pattern as `ActualWizardModel`.
class ReturnWizardModel {
  ReturnWizardModel({
    required this.id,
    required this.lines,
  });

  final int id;
  final List<ReturnWizardLine> lines;
}

class ReturnWizardLine {
  ReturnWizardLine({
    required this.id,
    required this.itemId,
    required this.productName,
    required this.lotName,
    required this.remainQty,
    required this.receivedQty,
    required this.totalUsingQty,
    required this.uom,
    this.returnQty = 0,
  });

  final int id;
  final int itemId;
  final String productName;
  final String lotName;
  final double remainQty;
  final double receivedQty;
  /// Server `total_using_qty` mirrors `mrp.mo.item.consumed_qty` —
  /// the qty already chewed up by previous Actual operations.
  final double totalUsingQty;
  final String uom;
  /// Mutable in-memory only — sent back via `write` before `action_confirm`.
  double returnQty;

  factory ReturnWizardLine.fromJson(Map<String, dynamic> json) {
    return ReturnWizardLine(
      id: (json['id'] as num).toInt(),
      itemId: _m2oId(json['item_id']) ?? 0,
      productName: json['product_name']?.toString() ??
          _m2oName(json['product_id']) ??
          '—',
      lotName: _m2oName(json['lot_id']) ?? '—',
      remainQty: _toDouble(json['remain_qty']),
      receivedQty: _toDouble(json['received_qty']),
      totalUsingQty: _toDouble(json['total_using_qty']),
      uom: _m2oName(json['uom_id']) ?? '',
      returnQty: _toDouble(json['return_qty']),
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
