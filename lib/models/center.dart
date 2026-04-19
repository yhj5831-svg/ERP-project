class CenterModel {
  final String id;           // UUID
  final String name;
  final String displayName;
  final String? centerCode;  // 선택적 (thats1_main 같은 코드)

  CenterModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.centerCode,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: json['id'],
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
      centerCode: json['center_code'],
    );
  }
}