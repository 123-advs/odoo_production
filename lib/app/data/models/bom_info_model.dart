/// Subset of `mrp.bom` data needed to compute material consumption for
/// the actual-qty wizard. Server's `_onchange_actual_qty` does:
///
/// ```python
/// ratio = actual_qty / bom.product_qty
/// needed_per_line = ratio * bom_line.required_qty
/// ```
///
/// where `required_qty` is a TCS extension on `mrp.bom.line` (computed from
/// `net_qty` × `(1 + loss_percent)`). Client mirrors this math so the user
/// sees breakdown in real-time without an extra server round-trip per
/// keystroke.
class BomInfoModel {
  BomInfoModel({
    required this.id,
    required this.productQty,
    required this.lines,
  });

  final int id;
  final double productQty;
  final List<BomLineInfo> lines;

  /// Required quantity for a given product at a given actual production qty.
  /// Returns 0 if the product is not in this BOM.
  double requiredQtyFor({required int productId, required double actualQty}) {
    final line = lines.where((l) => l.productId == productId).firstOrNull;
    if (line == null || productQty <= 0) return 0;
    return (actualQty / productQty) * line.requiredQty;
  }
}

class BomLineInfo {
  BomLineInfo({
    required this.productId,
    required this.requiredQty,
  });

  final int productId;
  final double requiredQty;

  factory BomLineInfo.fromJson(Map<String, dynamic> json) {
    return BomLineInfo(
      productId: _m2oId(json['product_id']) ?? 0,
      requiredQty: _toDouble(json['required_qty']),
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
}

extension _IterableFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
