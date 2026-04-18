class CenterModel {
  final String id;
  final String centerCode;
  final String name;
  final String displayName;

  CenterModel({
    required this.id,
    required this.centerCode,
    required this.name,
    required this.displayName,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: json['id'],
      centerCode: json['center_code'],
      name: json['name'],
      displayName: json['display_name'],
    );
  }
}