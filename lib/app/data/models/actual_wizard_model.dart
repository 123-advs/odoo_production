/// Snapshot of `mrp.mo.actual.wizard` after `_build_and_create`.
class ActualWizardModel {
  ActualWizardModel({
    required this.id,
    required this.targetQty,
    required this.remainQty,
    required this.lines,
    this.productSemiName,
  });

  final int id;
  final double targetQty;
  final double remainQty;
  final String? productSemiName;
  final List<ActualWizardLine> lines;

  factory ActualWizardModel.fromJson(
    Map<String, dynamic> json, {
    required List<ActualWizardLine> lines,
  }) {
    return ActualWizardModel(
      id: (json['id'] as num).toInt(),
      targetQty: _toDouble(json['target_qty']),
      remainQty: _toDouble(json['remain_qty']),
      productSemiName: json['product_semi_name']?.toString(),
      lines: lines,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class ActualWizardLine {
  ActualWizardLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.lotName,
    required this.receivedQty,
    required this.remainQty,
    required this.uom,
    this.usingQty = 0,
    this.otherLoss = 0,
  });

  final int id;
  final int productId;
  final String productName;
  final String lotName;
  final double receivedQty;
  final double remainQty;
  final String uom;
  /// Mutable in-memory only — sent back to the server with `write` before
  /// `action_confirm`.
  double usingQty;
  /// Other loss (waste / scrap / shrinkage). Tracked alongside using_qty
  /// on `mrp.mo.actual.wizard.line.other_loss`.
  double otherLoss;

  factory ActualWizardLine.fromJson(Map<String, dynamic> json) {
    return ActualWizardLine(
      id: (json['id'] as num).toInt(),
      productId: _m2oId(json['product_id']) ?? 0,
      productName: json['product_name']?.toString() ??
          _m2oName(json['product_id']) ??
          '—',
      lotName: _m2oName(json['lot_id']) ?? '—',
      receivedQty: _toDouble(json['received_qty']),
      remainQty: _toDouble(json['remain_qty']),
      uom: _m2oName(json['uom_id']) ?? '',
      usingQty: _toDouble(json['using_qty']),
      otherLoss: _toDouble(json['other_loss']),
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
