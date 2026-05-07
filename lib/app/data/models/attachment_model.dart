/// Row of `mrp.mo.attachment`.
class AttachmentModel {
  AttachmentModel({
    required this.id,
    required this.fileName,
    this.remark,
    this.uploadByName,
    this.uploadDate,
  });

  final int id;
  final String fileName;
  final String? remark;
  final String? uploadByName;
  final DateTime? uploadDate;

  /// Static URL to download the binary. Matches `action_download`'s URL format.
  String downloadPath() =>
      '/web/content?model=mrp.mo.attachment&id=$id&field=file&filename_field=file_name&download=true';

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: (json['id'] as num).toInt(),
      fileName: json['file_name']?.toString() ?? 'Untitled',
      remark: _str(json['remark']),
      uploadByName: _m2oName(json['upload_by']),
      uploadDate: _parseDt(json['upload_date']),
    );
  }

  static String? _str(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  static String? _m2oName(dynamic v) {
    if (v is List && v.length >= 2) return v[1]?.toString();
    return null;
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }
}
