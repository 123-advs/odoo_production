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
  final double totalUsingQty;
  final String uom;
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
