/// Row of `standard.issue` Used to tag OEE downtime
///
/// `operatingStatus`:
///   - `on` = normal/start-side issues
///   - `off` = downtime / pause-side reasons
class IssueModel {
  IssueModel({
    required this.id,
    required this.code,
    required this.name,
    required this.operatingStatus,
  });

  final int id;
  final String code;
  final String name;
  final String operatingStatus;

  String get displayName => '[$code] $name';

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: (json['id'] as num).toInt(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      operatingStatus: json['operating_status']?.toString() ?? 'on',
    );
  }
}
